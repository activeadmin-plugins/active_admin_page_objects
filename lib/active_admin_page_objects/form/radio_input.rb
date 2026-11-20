# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A radio input. `choose` picks a radio button by its label.
    class RadioInput < Input
      Form.register_type("radio", self)

      # The labels of the radio buttons.
      # @return [Array<String>]
      def options
        choices.map(&:first)
      end

      # The label of the chosen radio button, or nil when none is chosen.
      # @return [String, nil]
      def selected
        choices.find { |_label, input| input.checked? }&.first
      end
    end
  end
end
