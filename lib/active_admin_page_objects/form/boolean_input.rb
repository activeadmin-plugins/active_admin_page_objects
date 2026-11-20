# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A boolean input: one checkbox. `fill(true)` ticks it.
    class BooleanInput < Input
      Form.register_type("boolean", self)

      # True when the checkbox is ticked.
      def checked?
        find("input[type=checkbox]").checked?
      end
    end
  end
end
