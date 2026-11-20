# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A check_boxes field: one checkbox per choice.
    class CheckBoxesField < Field
      Form.register_type("check_boxes", self)

      # Ticks the checkboxes labelled +labels+ and unticks the others.
      def fill(labels)
        labels = Array(labels).map(&:to_s)
        uncheck(*(checked - labels))
        check(*labels)
      end

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
