# frozen_string_literal: true

module ActiveAdminPageObjects
  # The fields of a formtastic form. Form includes it. A field is named by its
  # attribute, as in `f.input :name`, or by its declared name when the section
  # declares fields:
  #
  #   section :form, ActiveAdminPageObjects::Form do
  #     field :email, "Email", ActiveAdminPageObjects::Form::StringField
  #     field :status, "Status", ActiveAdminPageObjects::Form::SelectField
  #   end
  module Fields
    def self.included(base)
      base.include(Declarations)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Declares the field +name+ with its +label+ and its section class
      # +type+. +name+ is the formtastic attribute.
      def field(name, label, type)
        declare_typed(:field, name, label, type: type)
      end
    end

    # The field +name+: its declared class, or else the class registered for
    # the wrapper's formtastic class, e.g. a SelectField for `as: :select`.
    # @raise [Capybara::ExpectationNotMet] when the page has a field of
    #   another class than the declared one
    # @return [Form::Field]
    def field(name)
      wrapper = find(:css, field_selector(name))
      build_declared(name, declaration_for(name), detected_field_class(wrapper), wrapper)
    end

    # Fills each field with its value, in the given order: `fill(name: "Acme", active: false)`.
    def fill(**values)
      values.each { |name, value| field(name).fill(value) }
    end

    # True when the field +name+ shows an inline error containing +text+.
    def has_field_error?(name, text = nil, **options)
      has_css?(field_error_selector(name), **(text ? { text: text } : {}), **options)
    end

    # Waits until the field +name+ shows no such inline error.
    def has_no_field_error?(name, text = nil, **options)
      has_no_css?(field_error_selector(name), **(text ? { text: text } : {}), **options)
    end

    # True when any field shows an inline error.
    def has_field_errors?(**options)
      has_css?(sel(:form_inline_error), **options)
    end

    # Waits until no field shows an inline error.
    def has_no_field_errors?(**options)
      has_no_css?(sel(:form_inline_error), **options)
    end

    # True when the inline errors are exactly +errors+: field name => message,
    # or an array of messages. No other field shows an error.
    def has_exact_field_errors?(**errors)
      expected = expected_field_errors(errors)
      eventually { shown_field_errors == expected }
    end

    # Waits until the inline errors differ from +errors+.
    def has_no_exact_field_errors?(**errors)
      expected = expected_field_errors(errors)
      eventually { shown_field_errors != expected }
    end

    # True when every declared field in scope has exactly its declared label.
    # The required marker is not part of the label. +only+ and +except+ take
    # declared names.
    def has_declared_fields?(only: nil, except: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, **options)
    end

    # Waits until a declared field in scope has another label, or is missing.
    def has_no_declared_fields?(only: nil, except: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, **options)
    end

    # Like #has_declared_fields?, and the page has no field that is not declared.
    def has_exact_fields?(only: nil, except: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, **options)
    end

    # Waits until the fields differ from the declared ones.
    def has_no_exact_fields?(only: nil, except: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, **options)
    end

    private

    def detected_field_class(wrapper)
      Form.field_class_for(wrapper)
    end

    # The attribute of the field +name+, checked against the declarations when fields are declared.
    def field_key(name)
      declaration_for(name)
      slug(name)
    end

    # Checks the name before #field_prefix queries the page.
    def field_selector(name)
      key = field_key(name)
      sel(:form_input, field_prefix, key)
    end

    def field_error_selector(name)
      "#{field_selector(name)} #{sel(:form_inline_error)}"
    end

    # The attributes of the input wrappers on the page.
    def field_keys(prefix)
      wrappers = all(:active_admin, :form_input_wrapper, visible: :all, wait: false)
      wrappers.filter_map { |wrapper| wrapper[:id].to_s[/\A#{Regexp.escape(prefix)}_(.+)_input\z/, 1] }
    end

    # Attribute => sorted inline error texts, for the fields that show an error.
    def shown_field_errors
      prefix = field_prefix
      field_keys(prefix).each_with_object({}) do |key, errors|
        texts = all(:css, "#{sel(:form_input, prefix, key)} #{sel(:form_inline_error)}", wait: false)
        errors[key] = texts.map { |error| squish(error.text) }.sort unless texts.empty?
      end
    end

    def expected_field_errors(errors)
      expected = errors.to_h { |name, messages| [field_key(name), Array(messages).map { |message| squish(message) }.sort] }
      expected.reject { |_key, messages| messages.empty? }
    end

    def declared_label_text(name, _declaration)
      wrapper_label_text(sel(:form_input, field_prefix, name))
    end

    def page_element_keys
      field_keys(field_prefix)
    end
  end
end
