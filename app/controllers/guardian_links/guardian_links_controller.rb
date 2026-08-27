# frozen_string_literal: true

module GuardianLinks
  class GuardianLinksController < ::Admin::AdminController
    requires_plugin GuardianLinks::PLUGIN_NAME

    def index
      links = GuardianLink.includes(:parent, :student).order(created_at: :desc)

      if params[:parent_id].present?
        links = links.where(parent_id: params[:parent_id].to_i)
      end

      if params[:student_id].present?
        links = links.where(student_id: params[:student_id].to_i)
      end

      if params[:search].present?
        term = "%#{params[:search].downcase}%"
        links = links.joins("INNER JOIN users AS parents ON parents.id = guardian_links.parent_id")
                     .joins("INNER JOIN users AS students ON students.id = guardian_links.student_id")
                     .where("LOWER(parents.username) LIKE :term OR LOWER(parents.name) LIKE :term OR LOWER(students.username) LIKE :term OR LOWER(students.name) LIKE :term", term: term)
      end

      render json: {
        guardian_links: links.map { |link| format_link(link) }
      }
    end

    def create
      parent = resolve_user(params[:parent_id], params[:parent_username])
      student = resolve_user(params[:student_id], params[:student_username])

      if parent.nil?
        return render_json_error(I18n.t("guardian_links.errors.parent_not_found"), status: 404)
      end

      if student.nil?
        return render_json_error(I18n.t("guardian_links.errors.student_not_found"), status: 404)
      end

      link = GuardianLink.new(
        parent: parent,
        student: student,
        relationship_type: params[:relationship_type].presence || "parent"
      )

      if link.save
        render json: {
          guardian_link: format_link(link)
        }
      else
        render_json_error(link.errors.full_messages.join(", "), status: 422)
      end
    end

    def destroy
      link = GuardianLink.find_by(id: params[:id].to_i)

      if link.nil?
        return render_json_error(I18n.t("guardian_links.errors.link_not_found"), status: 404)
      end

      link.destroy!
      render json: success_json
    end

    private

    def format_link(link)
      {
        id: link.id,
        parent_id: link.parent_id,
        student_id: link.student_id,
        relationship_type: link.relationship_type,
        created_at: link.created_at,
        parent: link.parent ? {
          id: link.parent.id,
          username: link.parent.username,
          name: link.parent.name,
          avatar_template: link.parent.avatar_template
        } : nil,
        student: link.student ? {
          id: link.student.id,
          username: link.student.username,
          name: link.student.name,
          avatar_template: link.student.avatar_template
        } : nil
      }
    end

    def resolve_user(id, username)
      if id.present?
        User.find_by(id: id.to_i)
      elsif username.present?
        User.find_by_username(username.to_s) || User.find_by("LOWER(username) = ?", username.to_s.downcase)
      else
        nil
      end
    end
  end
end
