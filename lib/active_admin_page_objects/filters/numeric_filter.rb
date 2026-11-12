# frozen_string_literal: true

require_relative "predicate_filter"

module ActiveAdminPageObjects
  # A numeric filter: predicate ("Equals", "Greater than", "Less than") and a
  # number input.
  class NumericFilter < PredicateFilter
    Filters.register_type("numeric", self)
  end
end
