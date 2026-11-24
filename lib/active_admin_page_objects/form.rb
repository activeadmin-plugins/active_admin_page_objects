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
  class Form < Section
    include SelectControl
    include Fields

    selector_key :form

    class << self
      # Declares the has_many block +name+ with its +heading+ (nil for
      # `heading: false`). The block declares the fields of each fieldset.
      # +name+ is the association. +visible+ is the Capybara option the block
      # is found with.
      def has_many(name, heading, visible: nil, &)
        fieldsets = Class.new(HasMany::Fieldset, &)
        type = Class.new(HasMany) { self.fieldset_class = fieldsets }
        declare_typed(:has_many, name, heading, type: type, kind: :has_many, visible: visible)
      end
    end

    # One `li.input` wrapper of the form. `Form#field` returns the declared
    # class, or the gem's subclass for the wrapper's formtastic class, or this
    # class. The wrapper is visible unless the lookup says otherwise, and so is
    # the control inside it: a `<select>` that a JavaScript select widget hides
    # or marks `aria-hidden="true"` is not found, unless the class overrides
    # `native_select_visibility`.
    class Field < Section
      include SelectControl

      # Sets the field: types text, picks a select option by label, or ticks a checkbox for `true`.
      # @raise [Capybara::ElementNotFound] when the field has a select that is hidden or `aria-hidden`
      def fill(value)
        # A hidden select goes to #choose_option too, which raises: the
        # fillable field next to it is a widget's search box.
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

      # True when every control of the field is disabled: each radio button
      # or checkbox of a field with choices. Does not wait.
      def disabled?
        states = control_states
        states.any? && states.all?
      end

      # True when a control of the field is not disabled. Does not wait.
      def enabled?
        control_states.include?(false)
      end

      private

      # Whether each control is disabled. A theme or a widget may hide the
      # control it replaces, so the lookup takes hidden controls too.
      def control_states
        all(:active_admin, :form_control, visible: :all, wait: false).map(&:disabled?)
      end

      # Each choice of a radio or check_boxes field: its label text and its
      # input, which a theme may hide to draw its own.
      def choices
        all(:active_admin, :form_choice, wait: false).map do |label|
          [label.text(:all).strip, label.find("input", visible: :all)]
        end
      end
    end

    # Clicks the submit button.
    def submit
      find(:active_admin, :form_submit, match: :first).click
    end

    # The `has_many` block of +association+, e.g. `has_many(:orders)`. A form
    # that declares has_many blocks takes the declared name. A hidden block is
    # found with `visible: :all`.
    # @raise [ArgumentError] when has_many blocks are declared and +association+ is not one of them
    # @return [HasMany]
    def has_many(association, visible: nil)
      declared = self.class.declarations.select { |_name, declaration| declaration[:kind] == :has_many }
      declaration = Declarations.lookup(declared, association)
      visibility = Declarations.visibility(declaration, visible)
      return HasMany.new(self, find(:css, sel(:has_many, association.to_s), **visibility)) unless declaration

      declaration[:type].new(self, find(:css, sel(:has_many, slug(association)), **visibility))
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

    # +messages+ as the exact matchers compare them: squished.
    # @api private
    # @return [Array<String>]
    def semantic_error_expectation(messages)
      messages.map { |text| squish(text) }
    end

    # The base errors the last `has_exact_semantic_errors?` or
    # `has_no_exact_semantic_errors?` call found on its last try, in page
    # order, or nil before the first call. The RSpec matchers build their
    # failure message from it.
    # @return [Array<String>, nil]
    attr_reader :last_semantic_errors

    private

    # Formtastic ids inputs `<object_name>_<attribute>_input`; the object name
    # is the prefix of the first namespaced field name.
    def field_prefix
      first_control_name[/\A[^\[]+/]
    end

    def exact_semantic_errors?(messages, strict_order)
      actual, expected = [semantic_errors, messages].map { |texts| semantic_error_expectation(texts) }
      @last_semantic_errors = actual
      strict_order ? actual == expected : actual.sort == expected.sort
    end

    # The heading of a declared has_many block: nil without the block, "" when it has no heading.
    def declared_label_text(name, declaration, **visibility)
      return super unless declaration[:kind] == :has_many

      container = sel(:has_many, name)
      return unless first(:css, container, minimum: 0, wait: false, **visibility)

      label_text("#{container} > h3", **visibility).to_s
    end

    # The fields outside the has_many blocks, and one entry per has_many block.
    def page_element_keys(**visibility)
      super + has_many_keys(**visibility)
    end

    # The associations of the has_many blocks, without the ones nested in a
    # fieldset: the hidden ones too, so that query takes every block.
    def has_many_keys(**visibility)
      every = all(:active_admin, :has_many_container, visible: :all, wait: false)
      nested = every.flat_map { |node| node.all(:active_admin, :has_many_container, visible: :all, wait: false).to_a }
      containers = all(:active_admin, :has_many_container, wait: false, **visibility)
      [containers, nested].map { |nodes| nodes.map { |node| has_many_key(node) } }.reduce(:-).uniq
    end

    # The association is the container's other class: `has_many_container orders`.
    def has_many_key(container)
      (class_names(container) - ["has_many_container"]).first
    end
  end
end

require_relative "form/string_field"
require_relative "form/select_field"
require_relative "form/boolean_field"
require_relative "form/radio_field"
require_relative "form/check_boxes_field"
require_relative "form/date_picker_field"
require_relative "form/file_field"
