# frozen_string_literal: true

require "date"

module ActiveAdminPageObjects
  # A date range filter: "from" and "to" text inputs with a jQuery UI
  # datepicker. The dates are typed in, not picked.
  class DateRangeFilter < Filter
    # Sets the range. Takes Date objects or ISO strings ("2026-01-31"); nil
    # or "" clears that end.
    # @raise [Date::Error] for a string that is not an ISO date
    def set(from, to = nil)
      fill_date(from_input, from)
      fill_date(to_input, to)
    end

    # True when the inputs hold +from+ and +to+.
    def has_range?(from, to = nil, **options)
      eventually(**options) { range_matches?(from, to) }
    end

    # Waits until the inputs no longer hold +from+ and +to+.
    def has_no_range?(from, to = nil, **options)
      eventually(**options) { !range_matches?(from, to) }
    end

    private

    def from_input
      find(:active_admin, :filter_range_from)
    end

    def to_input
      find(:active_admin, :filter_range_to)
    end

    def iso(value)
      iso_date(value)
    end

    def fill_date(input, value)
      value = Date.iso8601(value) if value.is_a?(String) && !value.empty?
      type_date(input, iso(value))
    end

    def range_matches?(from, to)
      from_input.value.to_s == iso(from) && to_input.value.to_s == iso(to)
    end
  end
end
