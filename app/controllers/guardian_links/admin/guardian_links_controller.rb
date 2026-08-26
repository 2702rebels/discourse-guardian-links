# frozen_string_literal: true

module GuardianLinks
  module Admin
    class GuardianLinksController < ::Admin::AdminController
      requires_plugin GuardianLinks::PLUGIN_NAME

      def index
        links = GuardianLink.includes(:parent, :student).order(created_at: :desc)

        if params[:parent_id].present?
          links = links.where(parent_id: params[:parent_id])
        end

        if params[:student_id].present?
          links = links.where(student_id: params[:student_id])
        end

        if params[:search].present?
          term = "%#{params[:search].downcase}%"
          links = links.joins("INNER JOIN users AS parents ON parents.id = guardian_links.parent_id")
                       .joins("INNER JOIN users AS students ON students.id = guardian_links.student_id")
                       .where("LOWER(parents.username) LIKE :term OR LOWER(parents.name) LIKE :term OR LOWER(students.username) LIKE :term OR LOWER(students.name) LIKE :term", term: term)
        end

        render_serialized(links, GuardianLinkSerializer, root: "guardian_links")
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
          render_serialized(link, GuardianLinkSerializer, root: "guardian_link")
        else
          render_json_error(link.errors.full_messages.join(", "), status: 422)
        end
      end

      def destroy
        link = GuardianLink.find_by(id: params[:id])

        if link.nil?
          return render_json_error(I18n.t("guardian_links.errors.link_not_found"), status: 404)
        end

        link.destroy!
        render json: success_json
      end

      private

      def resolve_user(id, username)
        if id.present?
          User.find_by(id: id)
        elsif username.present?
          User.find_by_username(username)
        else
          nil
        end
      end
    end
  end
end
