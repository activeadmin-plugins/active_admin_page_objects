# frozen_string_literal: true

class Customer < ActiveRecord::Base
  STATUSES = %w[active pending closed].freeze
  TIERS = %w[Bronze Silver Gold].freeze
  CHANNELS = %w[Email Phone Post].freeze

  belongs_to :category, optional: true
  has_many :orders, dependent: :destroy

  accepts_nested_attributes_for :orders, allow_destroy: true

  serialize :channels, type: Array, coder: JSON
  attr_accessor :password

  validates :name, presence: true
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
  validate :base_rules

  def self.ransackable_attributes(_auth = nil) = %w[id name email external_id status balance active category_id created_at]
  def self.ransackable_associations(_auth = nil) = %w[category]

  # The check_boxes input also posts a blank value.
  def channels=(values)
    super(Array(values).compact_blank)
  end

  private

  def base_rules
    errors.add(:base, "Name is reserved") if name == "Reserved"
    errors.add(:base, "Balance is negative") if balance.to_d.negative?
  end
end
