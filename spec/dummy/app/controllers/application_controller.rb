# frozen_string_literal: true

class ApplicationController < ActionController::Base
  DemoUser = Struct.new(:name) do
    def to_s = name
  end

  private

  def current_admin_user
    DemoUser.new("Demo Admin")
  end
end
