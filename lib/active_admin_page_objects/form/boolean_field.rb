# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A boolean field: one checkbox. `fill(true)` ticks it, `fill(false)` unticks it.
    class BooleanField < Field
      Form.register_type("boolean", self)

      # Ticks the checkbox for a truthy +value+ and unticks it otherwise.
      def fill(value)
        checkbox.set(value ? true : false)
      end

      # True when the checkbox is ticked.
      def checked?
        checkbox.checked?
      end

      private

      def checkbox
        find("input[type=checkbox]")
      end
    end
  end
end
