# frozen_string_literal: true

require_relative "string_field"

module ActiveAdminPageObjects
  class Form
    # An `as: :datepicker` field: a text input with a jQuery UI datepicker.
    # The date is typed in, not picked.
    class DatePickerField < StringField
      Form.register_type("datepicker", self)

      # Types the date: a Date, or a string such as "2026-01-31".
      def fill(value)
        input.set(value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value.to_s)
        # jQuery UI opens the datepicker when the input gets focus, over the
        # inputs below; Escape closes it.
        input.send_keys(:escape) if input[:class].to_s.split.include?("hasDatepicker")
      end
    end
  end
end
