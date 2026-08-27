# frozen_string_literal: true

class GuardianLinkSerializer < ApplicationSerializer
  attributes :id, :parent_id, :student_id, :relationship_type, :created_at, :parent, :student

  def parent
    return nil unless object.parent
    user_data(object.parent)
  end

  def student
    return nil unless object.student
    user_data(object.student)
  end

  def relationship_type
    object.relationship_type
  end

  private

  def user_data(user)
    {
      id: user.id,
      username: user.username,
      name: user.name,
      avatar_template: user.avatar_template
    }
  end
end
