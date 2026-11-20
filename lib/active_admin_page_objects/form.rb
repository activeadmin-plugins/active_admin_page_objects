# frozen_string_literal: true

module ActiveAdminPageObjects
  # A formtastic resource form (new and edit pages). Inputs are keyed by the
  # attribute: `fill(:name, with: "Acme")`.
  class Form < Section
    include SelectControl

    selector_key :form

    # One `li.input` wrapper of the form.
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
    end

    # The input wrapper for attribute +key+.
    # @return [Input]
    def input(key)
      Input.new(self, find(:css, sel(:form_input, object_name, slug(key))))
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

    def input_error_selector(key)
      "#{sel(:form_input, object_name, slug(key))} #{sel(:form_inline_error)}"
    end
  end
end
