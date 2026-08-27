# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuardianLink, type: :model do
  fab!(:parent) { Fabricate(:user) }
  fab!(:parent2) { Fabricate(:user) }
  fab!(:student) { Fabricate(:user) }
  fab!(:student2) { Fabricate(:user) }

  describe "validations" do
    it "creates a valid link with default relationship_type" do
      link = GuardianLink.create!(parent: parent, student: student)
      expect(link).to be_valid
      expect(link.relationship_type).to eq("parent")
    end

    it "creates a valid link with custom relationship_type" do
      link = GuardianLink.create!(parent: parent, student: student, relationship_type: "mother")
      expect(link.relationship_type).to eq("mother")
    end

    it "requires parent_id" do
      link = GuardianLink.new(student: student, relationship_type: "parent")
      expect(link).not_to be_valid
      expect(link.errors[:parent_id]).to be_present
    end

    it "requires student_id" do
      link = GuardianLink.new(parent: parent, relationship_type: "parent")
      expect(link).not_to be_valid
      expect(link.errors[:student_id]).to be_present
    end

    it "prevents self-linking" do
      link = GuardianLink.new(parent: parent, student: parent, relationship_type: "parent")
      expect(link).not_to be_valid
      expect(link.errors[:base]).to include("A user cannot be linked as their own guardian or student")
    end

    it "enforces uniqueness of parent and student combination" do
      GuardianLink.create!(parent: parent, student: student, relationship_type: "parent")
      duplicate = GuardianLink.new(parent: parent, student: student, relationship_type: "mother")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:parent_id]).to be_present
    end

    it "allows a parent to be linked to multiple different students" do
      link1 = GuardianLink.create!(parent: parent, student: student, relationship_type: "parent")
      link2 = GuardianLink.create!(parent: parent, student: student2, relationship_type: "parent")
      expect(link1).to be_persisted
      expect(link2).to be_persisted
    end

    it "allows a student to be linked to multiple different parents" do
      link1 = GuardianLink.create!(parent: parent, student: student, relationship_type: "father")
      link2 = GuardianLink.create!(parent: parent2, student: student, relationship_type: "mother")
      expect(link1).to be_persisted
      expect(link2).to be_persisted
    end
  end

  describe "database cascading" do
    it "cascades deletion when parent user is destroyed" do
      link = GuardianLink.create!(parent: parent, student: student, relationship_type: "parent")
      parent.destroy!
      expect(GuardianLink.find_by(id: link.id)).to be_nil
    end

    it "cascades deletion when student user is destroyed" do
      link = GuardianLink.create!(parent: parent, student: student, relationship_type: "parent")
      student.destroy!
      expect(GuardianLink.find_by(id: link.id)).to be_nil
    end
  end
end
