# frozen_string_literal: true

class LineItem < ActiveRecord::Base
  KINDS = %w[Goods Service].freeze

  belongs_to :order

  # Not stored: the form shows it as a check_boxes input.
  attr_accessor :tags

  validates :quantity, numericality: { greater_than: 0, allow_nil: true }
end
