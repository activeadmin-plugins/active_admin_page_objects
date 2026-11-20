# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A text field: string, email, url, phone, password, number or text.
    class StringField < Field
      %w[string email url phone password number text].each { |input_class| Form.register_type(input_class, self) }

      # Types +value+ into the input.
      def fill(value)
        input.set(value)
      end

      # The input's value.
      # @return [String]
      def value
        input.value
      end

      private

      def input
        find(:fillable_field, match: :first)
      end
    end
  end
end
