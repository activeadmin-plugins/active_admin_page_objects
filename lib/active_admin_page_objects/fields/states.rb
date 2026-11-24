# frozen_string_literal: true

module ActiveAdminPageObjects
  module Fields
    # `has_disabled_field?` and `has_enabled_field?` for a section whose
    # `field(name, visible:)` returns a Form::Field.
    module States
      # True when the field +name+ is disabled: every control of it is, as
      # Form::Field#disabled? tells. A hidden field is found with `visible: :all`.
      # @raise [DeclaredClassMismatch] when the page has a field of another
      #   class than the declared one
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
      # that is not on the page is neither disabled nor enabled.
      def field_state?(name, state, expected, visible: nil, wait: Capybara.default_max_wait_time)
        mismatch = nil
        result = eventually(wait: wait) do
          (field_on_page(name, visible)&.public_send(state) || false) == expected
        rescue DeclaredClassMismatch => e
          # Waiting does not change the class: stop, and raise outside the retry.
          mismatch = e
          break
        end
        mismatch ? raise(mismatch) : result
      end

      # The field, or nil when the page has none. Inside the retry the lookup does not wait.
      def field_on_page(name, visible)
        field(name, visible: visible)
      rescue Capybara::ElementNotFound => e
        raise if e.is_a?(DeclaredClassMismatch)
      end
    end
  end
end
