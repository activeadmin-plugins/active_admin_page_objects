# frozen_string_literal: true

module ActiveAdminPageObjects
  # Drives a native <select> inside a scope node. Mixed into sections; every
  # method takes the node that holds one select. A select that is hidden or
  # marked `aria-hidden="true"` is not found unless the class overrides
  # #native_select_visibility. Gems that render a JS select widget prepend a
  # module into ActiveAdminPageObjects::SelectControl to drive it, which
  # reaches filters and forms at once.
  module SelectControl
    private

    # The Capybara `visible:` value every lookup of the native <select> takes:
    # `:all`, `:hidden`, `:visible`, `true` or `false`. nil leaves it out, so
    # `Capybara.ignore_hidden_elements` decides. Override it to return `:all`
    # in a class that drives a widget and reads the select the widget hides.
    # A lookup of visible elements also leaves out an `aria-hidden` select.
    def native_select_visibility
      nil
    end

    # The `visible:` option of a native <select> lookup, as a hash.
    def native_select_lookup
      visible = native_select_visibility
      visible.nil? ? {} : { visible: visible }
    end

    # True when a native <select> lookup takes +select+. A widget may hide its
    # select with CSS that the driver reports as visible, and mark it
    # `aria-hidden="true"`.
    def native_select_shown?(select)
      visible = native_select_visibility
      visible = Capybara.ignore_hidden_elements if visible.nil?
      ![true, :visible].include?(visible) || select["aria-hidden"] != "true"
    end

    def native_select(scope)
      scope.find("select", **native_select_lookup) { |select| native_select_shown?(select) }
    end

    def choose_option(scope, label)
      native_select(scope).select(label, **native_select_lookup)
    end

    # The queries below find the select first, so none of them passes or
    # fails on a select that is not found: they raise.
    def selected_option?(scope, label)
      native_select(scope)
      scope.has_select?(selected: label, **native_select_lookup) { |select| native_select_shown?(select) }
    end

    def not_selected_option?(scope, label)
      native_select(scope)
      scope.has_no_select?(selected: label, **native_select_lookup) { |select| native_select_shown?(select) }
    end

    # An option is as visible as its select, so the option lookups of a found
    # select, here and in the sections, take hidden options too.
    def option_offered?(scope, label)
      native_select(scope).has_css?("option", exact_text: label, visible: :all)
    end

    def option_not_offered?(scope, label)
      native_select(scope).has_no_css?("option", exact_text: label, visible: :all)
    end

    def control_disabled?(scope)
      native_select(scope)
      scope.has_css?("select[disabled]", **native_select_lookup) { |select| native_select_shown?(select) }
    end

    def control_enabled?(scope)
      native_select(scope)
      scope.has_no_css?("select[disabled]", **native_select_lookup) { |select| native_select_shown?(select) }
    end

    def chosen_item?(scope, label)
      selected_option?(scope, label)
    end

    def no_chosen_item?(scope, label)
      not_selected_option?(scope, label)
    end
  end
end
