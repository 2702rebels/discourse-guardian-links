# frozen_string_literal: true

# name: discourse-guardian-links
# about: Relational parent/guardian and student linking for Discourse with PostgreSQL integrity and zero profile exposure
# version: 0.1.0
# authors: FRC 2702 Rebels
# url: https://github.com/2702rebels/discourse-guardian-links
# required_version: 2.7.0

enabled_site_setting :guardian_links_enabled

register_asset "stylesheets/guardian-links-admin.scss"

after_initialize do
  module ::GuardianLinks
    PLUGIN_NAME = "discourse-guardian-links"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace GuardianLinks
    end
  end

  require_relative "app/models/guardian_link"
  require_relative "app/serializers/guardian_link_serializer"
  require_relative "app/controllers/guardian_links/admin/guardian_links_controller"

  GuardianLinks::Engine.routes.draw do
    scope "/admin/plugins/guardian-links", as: "admin_guardian_links" do
      get "/" => "admin/guardian_links#index"
      post "/" => "admin/guardian_links#create"
      delete "/:id" => "admin/guardian_links#destroy"
    end
  end

  Discourse::Application.routes.append do
    mount ::GuardianLinks::Engine, at: "/"
  end

  add_admin_route "guardian_links.admin_title", "guardian-links"
end
