# frozen_string_literal: true

module ActiveAdminPageObjects
  # Drives a native <select> inside a scope node. Mixed into sections; every
  # method takes the node that holds one select. Gems that render a JS select
  # widget prepend a module into ActiveAdminPageObjects::SelectControl to drive
  # it, which reaches filters and forms at once.
  module SelectControl
    private

    def native_select(scope)
      scope.find("select", visible: :all)
    end

    def choose_option(scope, label)
      native_select(scope).select(label)
    end

    def selected_option?(scope, label)
      scope.has_select?(selected: label, visible: :all)
    end

    def not_selected_option?(scope, label)
      scope.has_no_select?(selected: label, visible: :all)
    end

    def option_offered?(scope, label)
      native_select(scope).has_css?("option", exact_text: label, visible: :all)
    end

    def option_not_offered?(scope, label)
      native_select(scope).has_no_css?("option", exact_text: label, visible: :all)
    end

    def control_disabled?(scope)
      scope.has_css?("select[disabled]", visible: :all)
    end

    def control_enabled?(scope)
      scope.has_no_css?("select[disabled]", visible: :all)
    end

    def chosen_item?(scope, label)
      selected_option?(scope, label)
    end

    def no_chosen_item?(scope, label)
      scope.has_no_select?(selected: label, visible: :all)
    end
  end
end
