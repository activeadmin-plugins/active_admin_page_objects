# frozen_string_literal: true

# The comment author: ActiveAdmin::Comment needs an ActiveRecord author.
class AdminUser < ActiveRecord::Base
  def to_s = name
end
