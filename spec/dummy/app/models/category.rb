# frozen_string_literal: true

class Category < ActiveRecord::Base
  has_many :customers, dependent: :nullify

  validates :name, presence: true

  def self.ransackable_attributes(_auth = nil) = %w[id name]
  def self.ransackable_associations(_auth = nil) = []
end
