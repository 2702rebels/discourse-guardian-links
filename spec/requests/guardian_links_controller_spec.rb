# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuardianLinks::GuardianLinksController, type: :request do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user) { Fabricate(:user) }
  fab!(:parent) { Fabricate(:user) }
  fab!(:student) { Fabricate(:user) }

  describe "#index" do
    it "denies access to non-admin users" do
      sign_in(user)
      get "/admin/plugins/guardian-links.json"
      expect(response.status).to eq(403).or eq(404)
    end

    it "lists links for admin" do
      sign_in(admin)
      GuardianLink.create!(parent: parent, student: student)

      get "/admin/plugins/guardian-links.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["guardian_links"].length).to eq(1)
      expect(json["guardian_links"][0]["parent"]["username"]).to eq(parent.username)
      expect(json["guardian_links"][0]["student"]["username"]).to eq(student.username)
    end
  end

  describe "#create" do
    it "creates a link using usernames" do
      sign_in(admin)

      post "/admin/plugins/guardian-links.json", params: {
        parent_username: parent.username,
        student_username: student.username,
        relationship_type: "mother"
      }

      expect(response.status).to eq(200)
      json = response.parsed_body
      expect(json["guardian_link"]["relationship_type"]).to eq("mother")
      expect(GuardianLink.where(parent_id: parent.id, student_id: student.id).count).to eq(1)
    end

    it "returns 404 if parent user does not exist" do
      sign_in(admin)

      post "/admin/plugins/guardian-links.json", params: {
        parent_username: "non_existent_user",
        student_username: student.username
      }

      expect(response.status).to eq(404)
    end
  end

  describe "#destroy" do
    it "removes a link" do
      sign_in(admin)
      link = GuardianLink.create!(parent: parent, student: student)

      delete "/admin/plugins/guardian-links/#{link.id}.json"
      expect(response.status).to eq(200)
      expect(GuardianLink.find_by(id: link.id)).to be_nil
    end
  end
end
