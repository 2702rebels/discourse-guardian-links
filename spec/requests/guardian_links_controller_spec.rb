# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuardianLinks::GuardianLinksController, type: :request do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user) { Fabricate(:user) }
  fab!(:parent) { Fabricate(:user, username: "parent_jane", name: "Jane Doe") }
  fab!(:parent2) { Fabricate(:user, username: "parent_john", name: "John Doe") }
  fab!(:student) { Fabricate(:user, username: "student_alex", name: "Alex Doe") }
  fab!(:student2) { Fabricate(:user, username: "student_sam", name: "Sam Smith") }

  before { SiteSetting.guardian_links_enabled = true }

  describe "Authorization & Plugin Gates" do
    it "denies unauthenticated requests" do
      get "/admin/plugins/guardian-links/links.json"
      expect(response.status).to eq(403).or eq(404)
    end

    it "denies access to regular non-staff users" do
      sign_in(user)
      get "/admin/plugins/guardian-links/links.json"
      expect(response.status).to eq(403).or eq(404)
    end

    it "returns 404 when plugin is disabled in site settings" do
      SiteSetting.guardian_links_enabled = false
      sign_in(admin)

      get "/admin/plugins/guardian-links/links.json"
      expect(response.status).to eq(404)
    end
  end

  describe "#index" do
    before do
      sign_in(admin)
      GuardianLink.create!(parent: parent, student: student, relationship_type: "mother")
      GuardianLink.create!(parent: parent2, student: student2, relationship_type: "father")
    end

    it "lists all links for admin" do
      get "/admin/plugins/guardian-links/links.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(2)
      usernames = json["guardian_links"].map { |l| l["parent"]["username"] }
      expect(usernames).to include(parent.username, parent2.username)
    end

    it "filters links by parent_id" do
      get "/admin/plugins/guardian-links/links.json", params: { parent_id: parent.id }
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(1)
      expect(json["guardian_links"][0]["parent"]["id"]).to eq(parent.id)
    end

    it "filters links by student_id" do
      get "/admin/plugins/guardian-links/links.json", params: { student_id: student2.id }
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(1)
      expect(json["guardian_links"][0]["student"]["id"]).to eq(student2.id)
    end

    it "searches links by parent username" do
      get "/admin/plugins/guardian-links/links.json", params: { search: "parent_jane" }
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(1)
      expect(json["guardian_links"][0]["parent"]["username"]).to eq("parent_jane")
    end

    it "searches links by student display name" do
      get "/admin/plugins/guardian-links/links.json", params: { search: "Sam Smith" }
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(1)
      expect(json["guardian_links"][0]["student"]["name"]).to eq("Sam Smith")
    end

    it "supports pagination with limit and page" do
      get "/admin/plugins/guardian-links/links.json", params: { limit: 1, page: 1 }
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(1)
    end
  end

  describe "#create" do
    before { sign_in(admin) }

    it "creates a link using usernames" do
      post "/admin/plugins/guardian-links/links.json", params: {
        parent_username: parent.username,
        student_username: student.username,
        relationship_type: "mother"
      }

      expect(response.status).to eq(200)
      json = response.parsed_body
      expect(json["guardian_link"]["relationship_type"]).to eq("mother")
      expect(json["guardian_link"]["parent"]["username"]).to eq(parent.username)
      expect(json["guardian_link"]["student"]["username"]).to eq(student.username)
      expect(GuardianLink.where(parent_id: parent.id, student_id: student.id).count).to eq(1)
    end

    it "creates a link when usernames include leading @" do
      post "/admin/plugins/guardian-links/links.json", params: {
        parent_username: "@#{parent.username}",
        student_username: "@#{student.username}",
        relationship_type: "guardian"
      }

      expect(response.status).to eq(200)
      json = response.parsed_body
      expect(json["guardian_link"]["relationship_type"]).to eq("guardian")
      expect(GuardianLink.where(parent_id: parent.id, student_id: student.id).count).to eq(1)
    end

    it "creates a link using numeric IDs" do
      post "/admin/plugins/guardian-links/links.json", params: {
        parent_id: parent.id,
        student_id: student.id,
        relationship_type: "father"
      }

      expect(response.status).to eq(200)
      expect(GuardianLink.where(parent_id: parent.id, student_id: student.id).count).to eq(1)
    end

    it "rejects self-linking with 422 Unprocessable Entity" do
      post "/admin/plugins/guardian-links/links.json", params: {
        parent_username: parent.username,
        student_username: parent.username
      }

      expect(response.status).to eq(422)
      expect(GuardianLink.where(parent_id: parent.id, student_id: parent.id).count).to eq(0)
    end

    it "rejects duplicate links with 422 Unprocessable Entity" do
      GuardianLink.create!(parent: parent, student: student, relationship_type: "parent")

      post "/admin/plugins/guardian-links/links.json", params: {
        parent_username: parent.username,
        student_username: student.username
      }

      expect(response.status).to eq(422)
    end

    it "returns 404 if parent user does not exist" do
      post "/admin/plugins/guardian-links/links.json", params: {
        parent_username: "non_existent_parent",
        student_username: student.username
      }

      expect(response.status).to eq(404)
    end

    it "returns 404 if student user does not exist" do
      post "/admin/plugins/guardian-links/links.json", params: {
        parent_username: parent.username,
        student_username: "non_existent_student"
      }

      expect(response.status).to eq(404)
    end
  end

  describe "#destroy" do
    before { sign_in(admin) }

    it "removes an existing link" do
      link = GuardianLink.create!(parent: parent, student: student, relationship_type: "parent")

      delete "/admin/plugins/guardian-links/links/#{link.id}.json"
      expect(response.status).to eq(200)
      expect(GuardianLink.find_by(id: link.id)).to be_nil
    end

    it "returns 404 when link does not exist" do
      delete "/admin/plugins/guardian-links/links/999999.json"
      expect(response.status).to eq(404)
    end
  end
end
