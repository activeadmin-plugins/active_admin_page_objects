# frozen_string_literal: true

module ActiveAdminPageObjects
  # A `has_many` block of a resource form, with the fieldsets of its nested
  # records. Reached with `form.has_many(:orders)`.
  class HasMany < Section
    selector_key :has_many

    # One nested record's fieldset. Inputs are keyed by the attribute, like the form's.
    class Fieldset < Section
      include SelectControl

      # The input wrapper for attribute +key+ of this nested record, typed like the form's.
      # @return [Form::Input]
      def input(key)
        wrapper = find(:css, sel(:form_input, prefix, slug(key)))
        Form.input_class_for(wrapper).new(self, wrapper)
      end

      # Sets the input for attribute +key+ to +with+.
      def fill(key, with:)
        input(key).fill(with)
      end

      # Picks +option+ in the select or radio input for attribute +key+.
      def choose(key, option)
        input(key).choose(option)
      end

      # Removes a new, unsaved fieldset, or ticks the delete checkbox of a saved one.
      # @raise [ArgumentError] when the fieldset has neither
      def remove
        if has_css?(sel(:has_many_remove), wait: false)
          find(:active_admin, :has_many_remove).click
        elsif has_css?(sel(:has_many_delete), wait: false)
          find(:active_admin, :has_many_delete).check
        else
          raise ArgumentError, "the fieldset has no remove link and no delete checkbox"
        end
      end

      # True when the delete checkbox of a saved record is ticked.
      def marked_for_destroy?
        has_css?(sel(:has_many_delete), wait: false) && find(:active_admin, :has_many_delete).checked?
      end

      private

      # Formtastic ids a field `<name with [] turned into _>`, so the prefix of
      # `customer[orders_attributes][0][reference]` is `customer_orders_attributes_0`.
      def prefix
        field = find("input[name*='['], select[name*='['], textarea[name*='[']", match: :first, visible: :all)
        field[:name].sub(/\[[^\]]*\]\z/, "").tr("[", "_").delete("]")
      end
    end

    # The block heading.
    # @return [String]
    def heading
      find(:css, "h3", match: :first).text.strip
    end

    # The number of fieldsets.
    # @return [Integer]
    def count
      all(:active_admin, :has_many_fieldset, wait: false).size
    end

    # All fieldsets, in page order.
    # @return [Array<Fieldset>]
    def fieldsets
      all(:active_admin, :has_many_fieldset, wait: false).map { |node| Fieldset.new(self, node) }
    end

    # The fieldset at +index+ (0-based), waiting for it to appear.
    # @return [Fieldset]
    def fieldset(index)
      Fieldset.new(self, all(:active_admin, :has_many_fieldset, minimum: index + 1)[index])
    end

    # Clicks the add link, waits for the new fieldset and returns it.
    # @return [Fieldset]
    def add
      before = count
      find(:active_admin, :has_many_add).click
      fieldset(before)
    end

    # Removes the fieldset at +index+: a new one with its remove link, a saved
    # one by ticking its delete checkbox.
    # @raise [ArgumentError] when the fieldset has neither
    def remove(index)
      fieldset(index).remove
    end

    # True when there are +count+ fieldsets, or any when +count+ is nil.
    def has_fieldsets?(count: nil, **options)
      has_css?(sel(:has_many_fieldset), **(count.nil? ? {} : { count: count }), **options)
    end

    # Waits until there are no fieldsets, or not +count+ fieldsets.
    def has_no_fieldsets?(count: nil, **options)
      has_no_css?(sel(:has_many_fieldset), **(count.nil? ? {} : { count: count }), **options)
    end
  end
end
