# frozen_string_literal: true

GuardianLinks::Engine.routes.draw do
  root to: "guardian_links#index"
  get "links" => "guardian_links#index"
  post "links" => "guardian_links#create"
  delete "links/:id" => "guardian_links#destroy"
end

Discourse::Application.routes.draw do
  mount ::GuardianLinks::Engine, at: "/admin/plugins/guardian-links"
end
