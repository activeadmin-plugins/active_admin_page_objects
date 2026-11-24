# frozen_string_literal: true

require_relative "select_filter"

module ActiveAdminPageObjects
  # A boolean filter: a select of "Any", "Yes" and "No".
  class BooleanFilter < SelectFilter
    # Selects `true`, `false`, or `nil` for "Any".
    def set(value)
      select_option(option_label(value))
    end

    # True when `true`, `false` or `nil` ("Any") is selected.
    def has_value?(value)
      has_selected?(option_label(value))
    end

    # Waits until +value+ is no longer selected.
    def has_no_value?(value)
      has_no_selected?(option_label(value))
    end

    private

    def option_label(value)
      option_text(native_select(root_element), value)
    end
  end
end
