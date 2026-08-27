# frozen_string_literal: true

GuardianLinks::Engine.routes.draw do
  get "/" => "guardian_links#index"
  post "/" => "guardian_links#create"
  delete "/:id" => "guardian_links#destroy"
end

Discourse::Application.routes.draw do
  mount ::GuardianLinks::Engine, at: "/admin/plugins/guardian-links", constraints: StaffConstraint.new
end
