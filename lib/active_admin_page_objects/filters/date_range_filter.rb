# frozen_string_literal: true

require "date"

module ActiveAdminPageObjects
  # A date range filter: "from" and "to" text inputs with a jQuery UI
  # datepicker. The dates are typed in, not picked.
  class DateRangeFilter < Filter
    Filters.register_type("date_range", self)

    # Sets the range. Takes Date objects or ISO strings ("2026-01-31"); nil
    # clears that end.
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
      value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value.to_s
    end

    def fill_date(input, value)
      input.set(iso(value.is_a?(String) ? Date.iso8601(value) : value))
      # jQuery UI opens the datepicker when the input gets focus, over the
      # buttons below; Escape closes it.
      input.send_keys(:escape) if input[:class].to_s.split.include?("hasDatepicker")
    end

    def range_matches?(from, to)
      from_input.value.to_s == iso(from) && to_input.value.to_s == iso(to)
    end
  end
end
