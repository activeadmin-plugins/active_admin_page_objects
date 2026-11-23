# frozen_string_literal: true

module ActiveAdminPageObjects
  # The fields of a formtastic form, or of one has_many fieldset. Form and
  # HasMany::Fieldset include it. A field is named by its attribute, as in
  # `f.input :name`, or by its declared name when the section declares fields:
  #
  #   section :form, ActiveAdminPageObjects::Form do
  #     field :email, "Email", ActiveAdminPageObjects::Form::StringField
  #     field :status, "Status", ActiveAdminPageObjects::Form::SelectField
  #   end
  module Fields
    # The name of the gem's Form field class per formtastic wrapper class. The
    # first entry whose class the wrapper carries wins.
    FIELD_CLASSES = {
      "string" => :StringField,
      "email" => :StringField,
      "url" => :StringField,
      "phone" => :StringField,
      "password" => :StringField,
      "number" => :StringField,
      "text" => :StringField,
      "select" => :SelectField,
      "boolean" => :BooleanField,
      "radio" => :RadioField,
      "check_boxes" => :CheckBoxesField,
      "datepicker" => :DatePickerField
    }.freeze
    private_constant :FIELD_CLASSES

    def self.included(base)
      base.include(Declarations)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Declares the field +name+ with its +label+ and its section class
      # +type+. +name+ is the formtastic attribute. +visible+ is the Capybara
      # option the field is found with, e.g. `:all` for a field that may be hidden.
      def field(name, label, type, visible: nil)
        declare_typed(:field, name, label, type: type, visible: visible)
      end
    end

    # The field +name+: its declared class, or else the gem's class for the
    # wrapper's formtastic class, e.g. a SelectField for `as: :select`. A
    # hidden field is found with `visible: :all`.
    # @raise [Capybara::ExpectationNotMet] when the page has a field of
    #   another class than the declared one
    # @return [Form::Field]
    def field(name, visible: nil)
      wrapper = find(:css, field_selector(name), **visibility_of(name, visible))
      build_declared(name, declaration_for(name), detected_field_class(wrapper), wrapper)
    end

    # Fills each field with its value, in the given order: `fill(name: "Acme", active: false)`.
    def fill(**values)
      values.each { |name, value| field(name).fill(value) }
    end

    # True when the field +name+ shows an inline error containing +text+.
    def has_field_error?(name, text = nil, **options)
      has_css?(field_error_selector(name), **field_error_options(name, text, options))
    end

    # Waits until the field +name+ shows no such inline error.
    def has_no_field_error?(name, text = nil, **options)
      has_no_css?(field_error_selector(name), **field_error_options(name, text, options))
    end

    # True when any field shows an inline error, has_many fieldsets included.
    def has_field_errors?(**options)
      has_css?(sel(:form_inline_error), **options)
    end

    # Waits until no field shows an inline error, has_many fieldsets included.
    def has_no_field_errors?(**options)
      has_no_css?(sel(:form_inline_error), **options)
    end

    # True when the inline errors are exactly +errors+: field name => message,
    # or an array of messages. No other field shows an error. The fields of
    # has_many fieldsets are left out: ask each fieldset. Every keyword is a
    # field name, so there is no `visible:` option: a hidden field counts only
    # when it is declared with `visible:`.
    def has_exact_field_errors?(**errors)
      expected = expected_field_errors(errors)
      eventually { (@last_field_errors = shown_field_errors) == expected }
    end

    # Waits until the inline errors differ from +errors+.
    def has_no_exact_field_errors?(**errors)
      expected = expected_field_errors(errors)
      eventually { (@last_field_errors = shown_field_errors) != expected }
    end

    # The inline errors the last `has_exact_field_errors?` or
    # `has_no_exact_field_errors?` call found on its last try, or nil before
    # the first call. The RSpec matchers build their failure message from it.
    # @return [Hash{String => Array<String>}, nil] attribute => sorted texts
    attr_reader :last_field_errors

    # True when every declared field in scope has exactly its declared label.
    # The required marker is not part of the label. +only+ and +except+ take
    # declared names. +visible+ is Capybara's option, for every field.
    def has_declared_fields?(only: nil, except: nil, visible: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, visible: visible, **options)
    end

    # Waits until a declared field in scope has another label, or is missing.
    def has_no_declared_fields?(only: nil, except: nil, visible: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, visible: visible, **options)
    end

    # Like #has_declared_fields?, and the page has no field that is not declared.
    def has_exact_fields?(only: nil, except: nil, visible: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, visible: visible, **options)
    end

    # Waits until the fields differ from the declared ones.
    def has_no_exact_fields?(only: nil, except: nil, visible: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, visible: visible, **options)
    end

    private

    # The gem's class for the wrapper's formtastic class, or Form::Field.
    def detected_field_class(wrapper)
      input_class = (FIELD_CLASSES.keys & wrapper[:class].to_s.split).first
      input_class ? Form.const_get(FIELD_CLASSES[input_class]) : Form::Field
    end

    # The attribute of the field +name+, checked against the declarations when fields are declared.
    def field_key(name)
      declaration = declaration_for(name)
      raise ArgumentError, "#{name.inspect} is declared as a has_many, not as a field" if declaration&.fetch(:kind) == :has_many

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

    def field_error_options(name, text, options)
      { **visibility_of(name), **(text ? { text: text } : {}), **options }
    end

    # The attributes of the input wrappers on the page. The wrappers inside a
    # has_many block belong to its fieldsets and are left out: the hidden ones
    # too, so that query takes every wrapper.
    def field_keys(prefix, **visibility)
      containers = all(:active_admin, :has_many_container, visible: :all, wait: false)
      nested = containers.flat_map { |node| wrapper_ids(node, visible: :all) }
      (wrapper_ids(self, **visibility) - nested).filter_map { |id| id[/\A#{Regexp.escape(prefix)}_(.+)_input\z/, 1] }
    end

    def wrapper_ids(scope, **visibility)
      scope.all(:active_admin, :form_input_wrapper, wait: false, **visibility).map { |wrapper| wrapper[:id].to_s }
    end

    # Attribute => sorted inline error texts, for the fields that show an error.
    def shown_field_errors
      prefix = field_prefix
      error_field_keys(prefix).each_with_object({}) do |key, errors|
        texts = inline_error_texts(sel(:form_input, prefix, key), Declarations.visibility(self.class.declarations[key]))
        errors[key] = texts.sort unless texts.empty?
      end
    end

    # The fields whose errors count: the visible ones, and the ones declared with `visible:`.
    def error_field_keys(prefix)
      declared = self.class.declarations.select { |_name, options| options[:kind] == :field && options.key?(:visible) }
      field_keys(prefix) | declared.keys
    end

    def inline_error_texts(css, visibility)
      all(:css, "#{css} #{sel(:form_inline_error)}", wait: false, **visibility).map { |error| squish(text_of(error, visibility)) }
    end

    def expected_field_errors(errors)
      expected = errors.to_h { |name, messages| [field_key(name), Array(messages).map { |message| squish(message) }.sort] }
      expected.reject { |_key, messages| messages.empty? }
    end

    def declared_label_text(name, _declaration, **visibility)
      wrapper_label_text(sel(:form_input, field_prefix, name), **visibility)
    end

    def page_element_keys(**visibility)
      field_keys(field_prefix, **visibility)
    end
  end
end
