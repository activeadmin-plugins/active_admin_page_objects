# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A check_boxes input: one checkbox per choice.
    class CheckBoxesInput < Input
      Form.register_type("check_boxes", self)

      # Ticks the checkboxes labelled +labels+.
      def check(*labels)
        labels.each { |label| root_element.check(label) }
      end

      # Unticks the checkboxes labelled +labels+.
      def uncheck(*labels)
        labels.each { |label| root_element.uncheck(label) }
      end

      # The labels of the ticked checkboxes.
      # @return [Array<String>]
      def checked
        choices.select { |_label, input| input.checked? }.map(&:first)
      end
    end
  end
end
