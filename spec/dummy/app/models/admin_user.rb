# frozen_string_literal: true

class AdminUser < ActiveRecord::Base
  def display_name = email
end
