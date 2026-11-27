# frozen_string_literal: true

class Order < ActiveRecord::Base
  STATES = %w[new paid shipped].freeze

  belongs_to :customer
  has_many :line_items, dependent: :destroy

  accepts_nested_attributes_for :line_items, allow_destroy: true

  def self.ransackable_attributes(_auth = nil) = %w[reference state quantity customer_id]
  def self.ransackable_associations(_auth = nil) = %w[customer]
end
