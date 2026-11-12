# frozen_string_literal: true

require_relative "predicate_filter"

module ActiveAdminPageObjects
  # A string filter: predicate ("Contains", "Equals", ...) and a text input.
  class StringFilter < PredicateFilter
    Filters.register_type("string", self)
  end
end
