# frozen_string_literal: true

GuardianLinks::Engine.routes.draw do
  scope "/admin/plugins/guardian-links", as: "admin_guardian_links" do
    get "/" => "admin/guardian_links#index"
    post "/" => "admin/guardian_links#create"
    delete "/:id" => "admin/guardian_links#destroy"
  end
end
