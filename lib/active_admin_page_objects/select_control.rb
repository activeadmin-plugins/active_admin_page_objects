# frozen_string_literal: true

module ActiveAdminPageObjects
  # Drives the <select> inside a scope node: a plain <select>, or Tom Select
  # when the scope holds a `.ts-wrapper`. Mixed into sections; every method
  # takes the node that holds one select.
  module SelectControl
    private

    def tom_select?(scope)
      scope.has_css?(sel(:tom_select), wait: false)
    end

    def require_tom_select!(scope, method)
      return if tom_select?(scope)

      raise TomSelectRequired, "#{self.class}##{method} needs Tom Select, but #{scope[:id] || 'the control'} is a plain <select>"
    end

    def native_select(scope)
      scope.find("select", visible: :all)
    end

    def choose_option(scope, label, search: nil)
      return native_select(scope).select(label) unless tom_select?(scope)

      dropdown = open_tom_select(scope)
      tom_select_search_input(scope, dropdown).send_keys(search) if search
      dropdown.find(sel(:tom_select_option), exact_text: label).click
      close_tom_select(scope)
    end

    # A multiple select keeps the dropdown open, and it can cover the next
    # element a spec clicks, such as the filters' submit button.
    def close_tom_select(scope)
      dropdown = sel(:tom_select_dropdown)
      return unless scope.has_css?(dropdown, visible: true, wait: false)

      scope.session.active_element.send_keys(:escape)
      scope.assert_no_selector(dropdown, visible: true)
    end

    def open_tom_select(scope)
      dropdown = sel(:tom_select_dropdown)
      scope.find(sel(:tom_select_control)).click unless scope.has_css?(dropdown, visible: true, wait: false)
      scope.find(dropdown, visible: true)
    end

    def tom_select_search_input(scope, dropdown)
      dropdown.first(sel(:tom_select_search), minimum: 0) || scope.find("#{sel(:tom_select_control)} input")
    end

    def selected_option?(scope, label)
      scope.has_select?(selected: label, visible: :all)
    end

    def option_offered?(scope, label)
      if tom_select?(scope)
        scope.has_css?("#{sel(:tom_select_dropdown)} #{sel(:tom_select_option)}", exact_text: label)
      else
        native_select(scope).has_css?("option", exact_text: label, visible: :all)
      end
    end

    def option_not_offered?(scope, label)
      if tom_select?(scope)
        scope.has_no_css?("#{sel(:tom_select_dropdown)} #{sel(:tom_select_option)}", exact_text: label)
      else
        native_select(scope).has_no_css?("option", exact_text: label, visible: :all)
      end
    end
  end
end
