# frozen_string_literal: true

class Order < ActiveRecord::Base
  STATES = %w[new paid shipped].freeze

  belongs_to :customer

  def self.ransackable_attributes(_auth = nil) = %w[reference state quantity customer_id]
  def self.ransackable_associations(_auth = nil) = %w[customer]
end
