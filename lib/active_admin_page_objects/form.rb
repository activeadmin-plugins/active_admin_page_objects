# frozen_string_literal: true

module ActiveAdminPageObjects
  # A formtastic resource form (new and edit pages). Inputs are keyed by the
  # attribute: `fill(:name, with: "Acme")`. Declare the fields, their labels
  # and optionally their input class on the section:
  #
  #   section :form, ActiveAdminPageObjects::Form do
  #     field :name, "Name"
  #     field :status, "Status", ActiveAdminPageObjects::Form::SelectInput
  #   end
  class Form < Section
    include SelectControl
    include Declarations

    selector_key :form

    class << self
      # Input class per formtastic input class, shared with subclasses.
      # @return [Hash{String => Class}]
      def types
        @types ||= superclass.respond_to?(:types) ? superclass.types : {}
      end

      # Registers +klass+ for wrappers carrying the +input_class+ CSS class.
      def register_type(input_class, klass)
        types[input_class.to_s] = klass
      end

      # The class registered for the wrapper's formtastic class, or Input.
      # @return [Class]
      def input_class_for(wrapper)
        classes = wrapper[:class].to_s.split
        types.each { |input_class, klass| return klass if classes.include?(input_class) }
        Input
      end

      # Declares the field of attribute +key+ with its +label+. With +type+,
      # `input(key)` raises unless the page has an input of that class.
      def field(key, label = nil, type = nil)
        declare(key, label, type)
      end
    end

    # One `li.input` wrapper of the form. `Form#input` returns the subclass
    # registered for the wrapper's formtastic class, or this class.
    class Input < Section
      include SelectControl

      # Sets the input: types text, picks a select option by label, or ticks a checkbox for `true`.
      def fill(value)
        if has_css?("select", visible: :all, wait: false)
          choose_option(root_element, value.to_s)
        elsif has_css?("input[type=checkbox]", wait: false) && [true, false].include?(value)
          find("input[type=checkbox]").set(value)
        else
          find(:fillable_field, match: :first).set(value)
        end
      end

      # Picks +option+ of a select or radio input.
      def choose(option)
        if has_css?("input[type=radio]", wait: false)
          root_element.choose(option)
        else
          choose_option(root_element, option)
        end
      end

      # The inline error texts.
      # @return [Array<String>]
      def errors
        all(:active_admin, :form_inline_error).map { |el| el.text.strip }
      end

      private

      # Each choice of a radio or check_boxes input: its label text and its input.
      def choices
        all(:active_admin, :form_choice, visible: :all, wait: false).map do |label|
          [label.text(:all).strip, label.find("input", visible: :all)]
        end
      end
    end

    # The input wrapper for attribute +key+, e.g. a SelectInput for `as: :select`.
    # @raise [Capybara::ExpectationNotMet] when the field is declared with another class
    # @return [Input]
    def input(key)
      declaration = declaration_for(key)
      wrapper = find(:css, input_selector(key))
      klass = self.class.input_class_for(wrapper)
      check_declared_type(key, declaration, klass)
      klass.new(self, wrapper)
    end

    # Sets the input for attribute +key+ to +with+.
    def fill(key, with:)
      input(key).fill(with)
    end

    # Picks +option+ in the select or radio input for attribute +key+.
    def choose(key, option)
      input(key).choose(option)
    end

    # Clicks the submit button.
    def submit
      find(:active_admin, :form_submit, match: :first).click
    end

    # True when the input for +key+ shows an inline error containing +text+.
    def has_input_error?(key, text = nil, **options)
      has_css?(input_error_selector(key), **(text ? { text: text } : {}), **options)
    end

    # Waits until the input for +key+ shows no such inline error.
    def has_no_input_error?(key, text = nil, **options)
      has_no_css?(input_error_selector(key), **(text ? { text: text } : {}), **options)
    end

    # True when every declared field has exactly its declared label. The
    # required marker is not part of the label.
    def has_declared_fields?(**options)
      declared_labels?(**options)
    end

    # Waits until a declared field has another label, or is missing.
    def has_no_declared_fields?(**options)
      no_declared_labels?(**options)
    end

    # True when the base-error list shows every one of +messages+ (or any
    # error when none are given).
    def has_semantic_errors?(*messages, **options)
      eventually(**options) do
        errors = semantic_errors
        messages.empty? ? errors.any? : messages.all? { |m| errors.any? { |e| same_text?(e, m) } }
      end
    end

    # Waits until the base-error list shows none of +messages+ (or no errors).
    def has_no_semantic_errors?(*messages, **options)
      eventually(**options) do
        errors = semantic_errors
        messages.empty? ? errors.empty? : messages.none? { |m| errors.any? { |e| same_text?(e, m) } }
      end
    end

    # The base-error texts.
    # @return [Array<String>]
    def semantic_errors
      all(:active_admin, :form_semantic_error, wait: false).map { |el| el.text.strip }
    end

    private

    # Formtastic ids inputs `<object_name>_<attribute>_input`; the object name
    # is the prefix of the first namespaced field name.
    def object_name
      field = find("input[name*='['], select[name*='['], textarea[name*='[']", match: :first, visible: :all)
      field[:name][/\A[^\[]+/]
    end

    # Checks the key before #object_name queries the page.
    def input_selector(key)
      declaration_for(key)
      sel(:form_input, object_name, slug(key))
    end

    def input_error_selector(key)
      "#{input_selector(key)} #{sel(:form_inline_error)}"
    end

    def declared_label_text(key)
      input_label_text(sel(:form_input, object_name, key))
    end
  end
end

require_relative "form/string_input"
require_relative "form/select_input"
require_relative "form/boolean_input"
require_relative "form/radio_input"
require_relative "form/check_boxes_input"
require_relative "form/date_picker_input"
