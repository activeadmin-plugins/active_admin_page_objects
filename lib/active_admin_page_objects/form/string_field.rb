# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A text field: string, email, url, phone, password, number or text.
    class StringField < Field
      # Types +value+ into the input.
      def fill(value)
        input.set(value)
      end

      # The input's value.
      # @return [String]
      def value
        input.value
      end

      # The text input or textarea.
      # @return [Capybara::Node::Element]
      def input
        find(:fillable_field, match: :first)
      end
    end
  end
end
