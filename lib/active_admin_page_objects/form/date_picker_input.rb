# frozen_string_literal: true

require_relative "string_input"

module ActiveAdminPageObjects
  class Form
    # An `as: :date_picker` input: a native `<input type="date">`.
    class DatePickerInput < StringInput
      Form.register_type("date_picker", self)

      # Sets the date: a Date, or a string such as "2026-01-31".
      def fill(value)
        field.set(value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value.to_s)
      end
    end
  end
end
