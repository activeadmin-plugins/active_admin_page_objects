# frozen_string_literal: true

class Document < ActiveRecord::Base
  STATES = %w[draft published].freeze
  KINDS = %w[Memo Invoice].freeze

  attr_reader :attachment

  def self.ransackable_attributes(_auth = nil) = %w[id name state]
  def self.ransackable_associations(_auth = nil) = []

  # Keeps the name of the uploaded file, which is all the specs need of it.
  def attachment=(file)
    @attachment = file
    self.attachment_name = file.original_filename
  end
end
