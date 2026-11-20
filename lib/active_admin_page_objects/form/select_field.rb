# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A select field. `fill` picks an option by its text.
    class SelectField < Field
      Form.register_type("select", self)

      # Picks the option labelled +label+.
      def fill(label)
        choose_option(root_element, label.to_s)
      end

      # The option texts, without the blank option.
      # @return [Array<String>]
      def options
        option_texts(option_nodes)
      end

      # The text of the selected option, or nil when the blank option is selected.
      # @return [String, nil]
      def selected
        option_texts(option_nodes.select(&:selected?)).first
      end

      private

      def option_nodes
        native_select(root_element).all("option", visible: :all, wait: false)
      end

      def option_texts(nodes)
        nodes.map { |option| option.text(:all).strip }.reject(&:empty?)
      end
    end
  end
end
