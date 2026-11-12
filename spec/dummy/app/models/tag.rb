# frozen_string_literal: true

class Tag < ActiveRecord::Base
  def self.ransackable_attributes(_auth = nil) = %w[name]
  def self.ransackable_associations(_auth = nil) = []
end
