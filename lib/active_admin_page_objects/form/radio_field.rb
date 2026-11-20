# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A radio field. `fill` picks a radio button by its label.
    class RadioField < Field
      Form.register_type("radio", self)

      # Picks the radio button labelled +option+.
      def fill(option)
        root_element.choose(option.to_s)
      end

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
