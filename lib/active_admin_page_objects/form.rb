# frozen_string_literal: true

module ActiveAdminPageObjects
  # A formtastic resource form (new and edit pages). Fields are named by the
  # attribute: `field(:email).fill("acme@example.com")`. Declare the fields
  # with their labels and section classes, and the has_many blocks, on the
  # section:
  #
  #   section :form, ActiveAdminPageObjects::Form do
  #     field :email, "Email", ActiveAdminPageObjects::Form::StringField
  #     field :status, "Status", ActiveAdminPageObjects::Form::SelectField
  #     has_many :orders, "Orders" do
  #       field :reference, "Reference", ActiveAdminPageObjects::Form::StringField
  #     end
  #   end
  #
  # Each declaration defines a method of its name: `form.status`, `form.orders`.
  class Form < Section
    include SelectControl
    include Fields

    selector_key :form

    class << self
      # Field class per formtastic input class, shared with subclasses.
      # @return [Hash{String => Class}]
      def types
        @types ||= superclass.respond_to?(:types) ? superclass.types : {}
      end

      # Registers +klass+ for wrappers carrying the +input_class+ CSS class.
      def register_type(input_class, klass)
        types[input_class.to_s] = klass
      end

      # The class registered for the wrapper's formtastic class, or Field.
      # @return [Class]
      def field_class_for(wrapper)
        classes = wrapper[:class].to_s.split
        types.each { |input_class, klass| return klass if classes.include?(input_class) }
        Field
      end

      # Declares the has_many block +name+ with its +heading+ (nil for
      # `heading: false`), and defines the method +name+ that returns its
      # HasMany. The block declares the fields of each fieldset. +attribute+
      # is the association, when it differs from +name+.
      # @raise [ArgumentError] when the section already has a method +name+
      def has_many(name, heading, attribute: name, &)
        fieldsets = Class.new(HasMany::Fieldset, &)
        type = Class.new(HasMany) { self.fieldset_class = fieldsets }
        declare_accessor(:has_many, name, heading, type: type, attribute: attribute)
      end
    end

    # One `li.input` wrapper of the form. `Form#field` returns the declared
    # class, or the subclass registered for the wrapper's formtastic class, or
    # this class.
    class Field < Section
      include SelectControl

      # Sets the field: types text, picks a select option by label, or ticks a checkbox for `true`.
      def fill(value)
        if has_css?("select", visible: :all, wait: false)
          choose_option(root_element, value.to_s)
        elsif has_css?("input[type=checkbox]", wait: false) && [true, false].include?(value)
          find("input[type=checkbox]").set(value)
        else
          find(:fillable_field, match: :first).set(value)
        end
      end

      # Picks +option+ of a select or radio field.
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

      # Each choice of a radio or check_boxes field: its label text and its input.
      def choices
        all(:active_admin, :form_choice, visible: :all, wait: false).map do |label|
          [label.text(:all).strip, label.find("input", visible: :all)]
        end
      end
    end

    # Clicks the submit button.
    def submit
      find(:active_admin, :form_submit, match: :first).click
    end

    # The `has_many` block of +association+, e.g. `has_many(:orders)`. A form
    # that declares has_many blocks takes the declared name.
    # @raise [ArgumentError] when has_many blocks are declared and +association+ is not one of them
    # @return [HasMany]
    def has_many(association)
      declared = self.class.declarations.select { |_name, declaration| declaration[:kind] == :has_many }
      declaration = Declarations.lookup(declared, association)
      return HasMany.new(self, find(:css, sel(:has_many, association.to_s))) unless declaration

      declaration[:type].new(self, find(:css, sel(:has_many, declaration[:attribute])))
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

    # True when the base-error list is exactly +messages+: the same texts, in
    # any order, or in the given order with +strict_order+.
    def has_exact_semantic_errors?(*messages, strict_order: false, **options)
      eventually(**options) { exact_semantic_errors?(messages, strict_order) }
    end

    # Waits until the base-error list differs from +messages+.
    def has_no_exact_semantic_errors?(*messages, strict_order: false, **options)
      eventually(**options) { !exact_semantic_errors?(messages, strict_order) }
    end

    # The base-error texts.
    # @return [Array<String>]
    def semantic_errors
      all(:active_admin, :form_semantic_error, wait: false).map { |el| el.text.strip }
    end

    private

    # Formtastic ids inputs `<object_name>_<attribute>_input`; the object name
    # is the prefix of the first namespaced field name.
    def field_prefix
      field = find("input[name*='['], select[name*='['], textarea[name*='[']", match: :first, visible: :all)
      field[:name][/\A[^\[]+/]
    end

    def detected_field_class(wrapper)
      self.class.field_class_for(wrapper)
    end

    def exact_semantic_errors?(messages, strict_order)
      actual, expected = [semantic_errors, messages].map { |texts| texts.map { |text| squish(text) } }
      strict_order ? actual == expected : actual.sort == expected.sort
    end

    # The heading of a declared has_many block: nil without the block, "" when it has no heading.
    def declared_label_text(name, declaration)
      return super unless declaration[:kind] == :has_many

      container = sel(:has_many, declaration[:attribute])
      return unless first(:css, container, minimum: 0, wait: false, visible: :all)

      label_text("#{container} > h3").to_s
    end

    # The fields outside the has_many blocks, and one entry per has_many block.
    def page_element_keys
      super + has_many_keys
    end

    # The associations of the has_many blocks, without the ones nested in a fieldset.
    def has_many_keys
      containers = all(:active_admin, :has_many_container, visible: :all, wait: false)
      nested = containers.flat_map { |node| node.all(:active_admin, :has_many_container, visible: :all, wait: false).to_a }
      [containers, nested].map { |nodes| nodes.map { |node| has_many_key(node) } }.reduce(:-).uniq
    end

    # The association is the container's other class: `has_many_container orders`.
    def has_many_key(container)
      (container[:class].to_s.split - ["has_many_container"]).first
    end
  end
end

require_relative "form/string_field"
require_relative "form/select_field"
require_relative "form/boolean_field"
require_relative "form/radio_field"
require_relative "form/check_boxes_field"
require_relative "form/date_picker_field"
