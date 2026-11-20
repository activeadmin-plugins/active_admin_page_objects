# frozen_string_literal: true

require_relative "string_input"

module ActiveAdminPageObjects
  class Form
    # An `as: :datepicker` input: a text input with a jQuery UI datepicker.
    # The date is typed in, not picked.
    class DatePickerInput < StringInput
      Form.register_type("datepicker", self)

      # Types the date: a Date, or a string such as "2026-01-31".
      def fill(value)
        field.set(value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value.to_s)
        # jQuery UI opens the datepicker when the input gets focus, over the
        # inputs below; Escape closes it.
        field.send_keys(:escape) if field[:class].to_s.split.include?("hasDatepicker")
      end
    end
  end
end
