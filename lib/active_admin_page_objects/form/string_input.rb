# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A text input: string, email, url, phone, password, number or text.
    class StringInput < Input
      %w[string email url phone password number text].each { |input_class| Form.register_type(input_class, self) }

      # Types +value+ into the field.
      def fill(value)
        field.set(value)
      end

      # The field's value.
      # @return [String]
      def value
        field.value
      end

      private

      def field
        find(:fillable_field, match: :first)
      end
    end
  end
end
