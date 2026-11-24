# frozen_string_literal: true

require_relative "string_field"

module ActiveAdminPageObjects
  class Form
    # An `as: :date_picker` field: a native `<input type="date">`.
    class DatePickerField < StringField
      # Sets the date: a Date, or a string such as "2026-01-31".
      def fill(value)
        input.set(iso_date(value))
      end
    end
  end
end
