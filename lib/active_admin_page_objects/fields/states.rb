# frozen_string_literal: true

module ActiveAdminPageObjects
  module Fields
    # `has_disabled_field?` and `has_enabled_field?` for the sections with fields.
    module States
      # True when the field +name+ is disabled: every control of it is, as
      # Form::Field#disabled? tells. A hidden field is found with `visible: :all`.
      def has_disabled_field?(name, **options)
        field_state?(name, :disabled?, true, **options)
      end

      # Waits until the field +name+ is not disabled, or is gone.
      def has_no_disabled_field?(name, **options)
        field_state?(name, :disabled?, false, **options)
      end

      # True when the field +name+ is enabled: a control of it is.
      def has_enabled_field?(name, **options)
        field_state?(name, :enabled?, true, **options)
      end

      # Waits until the field +name+ is not enabled, or is gone.
      def has_no_enabled_field?(name, **options)
        field_state?(name, :enabled?, false, **options)
      end

      private

      # Waits until the field +name+ answers +state+ with +expected+. A field
      # that is not on the page is neither disabled nor enabled. A declared
      # class answers for its field, so its own `disabled?` counts.
      def field_state?(name, state, expected, visible: nil, wait: Capybara.default_max_wait_time)
        css = field_selector(name)
        visibility = visibility_of(name, visible)
        type = declaration_for(name)&.fetch(:type) || Form::Field
        eventually(wait: wait) do
          wrapper = first(:css, css, minimum: 0, wait: false, **visibility)
          (!wrapper.nil? && type.new(self, wrapper).public_send(state)) == expected
        end
      end
    end
  end
end
