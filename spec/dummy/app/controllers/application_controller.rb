# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  def current_admin_user
    AdminUser.find_or_create_by!(name: "Demo Admin")
  end
end
