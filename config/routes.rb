# frozen_string_literal: true

GuardianLinks::Engine.routes.draw do
  get "/admin/plugins/guardian-links" => "guardian_links#index"
  post "/admin/plugins/guardian-links" => "guardian_links#create"
  delete "/admin/plugins/guardian-links/:id" => "guardian_links#destroy"
end
