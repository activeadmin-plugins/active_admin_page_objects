# frozen_string_literal: true

require_relative "string_field"

module ActiveAdminPageObjects
  class Form
    # An `as: :datepicker` field: a text input with a jQuery UI datepicker.
    # The date is typed in, not picked.
    class DatePickerField < StringField
      # Types the date: a Date, or a string such as "2026-01-31".
      def fill(value)
        type_date(input, iso_date(value))
      end
    end
  end
end
