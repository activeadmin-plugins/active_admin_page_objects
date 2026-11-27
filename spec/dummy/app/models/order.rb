# frozen_string_literal: true

class Order < ActiveRecord::Base
  STATES = %w[new paid shipped].freeze

  belongs_to :customer

  # Not stored: the form shows it as a check_boxes input.
  attr_accessor :tags

  validates :quantity, numericality: { greater_than: 0, allow_nil: true }

  def self.ransackable_attributes(_auth = nil) = %w[reference state quantity customer_id]
  def self.ransackable_associations(_auth = nil) = %w[customer]
end
