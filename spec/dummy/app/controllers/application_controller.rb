# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  def current_admin_user
    AdminUser.first_or_create!(email: "admin@example.com")
  end
end
