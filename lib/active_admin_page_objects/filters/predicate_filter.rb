# frozen_string_literal: true

module ActiveAdminPageObjects
  # A filter with a predicate select and one value input (string, numeric).
  # Changing the predicate renames the input in JavaScript, so a predicate
  # other than the current one needs a JavaScript driver. A hidden predicate
  # select is not found: see SelectControl.
  class PredicateFilter < Filter
    include SelectControl

    # Picks +predicate+ and types +with+. The predicate is the option label
    # ("Equals") or the ransack suffix (`:eq`); nil keeps the current one.
    def fill_in(with:, predicate: nil)
      choose_option(predicate_scope, predicate_label(predicate)) if predicate
      value_input.set(with.to_s)
    end

    # True when the input holds +value+ and +predicate+ is selected.
    def has_value?(value, predicate: nil, **options)
      eventually(**options) { value_matches?(value, predicate) }
    end

    # Waits until the input no longer holds +value+ with +predicate+.
    def has_no_value?(value, predicate: nil, **options)
      eventually(**options) { !value_matches?(value, predicate) }
    end

    # The selected predicate label, or nil without a visible predicate select.
    # @return [String, nil]
    def predicate
      select = predicate_select
      select && selected_label(select)
    end

    private

    def value_input
      find(:active_admin, :filter_value)
    end

    def predicate_select
      first(:active_admin, :filter_predicate, minimum: 0, **native_select_lookup) { |select| native_select_shown?(select) }
    end

    def predicate_select!
      predicate_select || raise(Capybara::ElementNotFound, "#{self.class} has no predicate select")
    end

    def predicate_scope
      predicate_select!.find(:xpath, "..")
    end

    def selected_label(select)
      select.find("option[value=\"#{select.value}\"]", visible: :all).text(:all).strip
    end

    def predicate_label(predicate)
      return predicate unless predicate.is_a?(Symbol)

      option = predicate_scope.first("option[value$=\"_#{predicate}\"]", visible: :all, minimum: 0)
      option ? option.text(:all).strip : raise(ArgumentError, "no #{predicate.inspect} predicate in #{self.class}")
    end

    def value_matches?(value, predicate)
      selected = selected_label(predicate_select!) if predicate
      return false unless value_input.value.to_s == value.to_s

      predicate.nil? || same_text?(selected, predicate_label(predicate))
    end
  end
end
