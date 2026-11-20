# frozen_string_literal: true

class Customer < ActiveRecord::Base
  STATUSES = %w[active pending closed].freeze

  belongs_to :category, optional: true
  has_many :orders, dependent: :destroy

  accepts_nested_attributes_for :orders, allow_destroy: true

  validates :name, presence: true
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
  validate :name_is_not_reserved

  def self.ransackable_attributes(_auth = nil) = %w[id name email status balance active category_id created_at]
  def self.ransackable_associations(_auth = nil) = %w[category]

  private

  def name_is_not_reserved
    errors.add(:base, "Name is reserved") if name == "Reserved"
  end
end
