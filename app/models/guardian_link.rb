# frozen_string_literal: true

class GuardianLink < ActiveRecord::Base
  belongs_to :parent, class_name: "User"
  belongs_to :student, class_name: "User"

  attribute :relationship_type, :string, default: "parent"

  validates :parent_id, presence: true
  validates :student_id, presence: true
  validates :relationship_type, presence: true
  validates :parent_id, uniqueness: { scope: :student_id, message: "is already linked to this student" }

  validate :cannot_link_to_self

  private

  def cannot_link_to_self
    if parent_id.present? && student_id.present? && parent_id == student_id
      errors.add(:base, "A user cannot be linked as their own guardian or student")
    end
  end
end
