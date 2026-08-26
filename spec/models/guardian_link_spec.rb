# frozen_string_literal: true

require "rails_helper"

RSpec.describe GuardianLink, type: :model do
  fab!(:parent) { Fabricate(:user) }
  fab!(:student) { Fabricate(:user) }

  describe "validations" do
    it "is valid with a parent and student" do
      link = GuardianLink.new(parent: parent, student: student)
      expect(link).to be_valid
    end

    it "requires a parent_id" do
      link = GuardianLink.new(student: student)
      expect(link).not_to be_valid
      expect(link.errors[:parent_id]).to be_present
    end

    it "requires a student_id" do
      link = GuardianLink.new(parent: parent)
      expect(link).not_to be_valid
      expect(link.errors[:student_id]).to be_present
    end

    it "prevents a user from linking to themselves" do
      link = GuardianLink.new(parent: parent, student: parent)
      expect(link).not_to be_valid
      expect(link.errors[:base]).to include("A user cannot be linked as their own guardian or student")
    end

    it "enforces uniqueness for a parent-student pair" do
      GuardianLink.create!(parent: parent, student: student)
      duplicate = GuardianLink.new(parent: parent, student: student)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:parent_id]).to be_present
    end
  end

  describe "associations" do
    it "cascades deletion when parent user is destroyed" do
      GuardianLink.create!(parent: parent, student: student)
      expect { parent.destroy! }.to change { GuardianLink.count }.by(-1)
    end

    it "cascades deletion when student user is destroyed" do
      GuardianLink.create!(parent: parent, student: student)
      expect { student.destroy! }.to change { GuardianLink.count }.by(-1)
    end
  end
end
