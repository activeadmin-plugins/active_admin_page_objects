# frozen_string_literal: true

module ActiveAdminPageObjects
  # A select filter. Drives a plain <select>, or Tom Select when the wrapper
  # holds a `.ts-wrapper`; #open, #create_option and #placeholder need Tom Select.
  class SelectFilter < Filter
    include SelectControl

    Filters.register_type("select", self)

    # Chooses the option labelled +label+. With Tom Select, types +search+
    # first (for remote-loaded options); a plain <select> ignores it.
    def select_option(label, search: nil)
      choose_option(root_element, label, search: search)
    end

    # Types +value+ and picks Tom Select's "Add ..." entry.
    def create_option(value)
      require_tom_select!(root_element, :create_option)
      dropdown = open_tom_select(root_element)
      tom_select_search_input(root_element, dropdown).send_keys(value)
      dropdown.find(sel(:tom_select_create), text: value).click
    end

    # Opens the Tom Select dropdown without choosing, for #has_option?.
    def open
      require_tom_select!(root_element, :open)
      open_tom_select(root_element)
    end

    # True when the control offers +label+ (Tom Select: call #open first).
    def has_option?(label)
      option_offered?(root_element, label)
    end

    # Waits until the control no longer offers +label+.
    def has_no_option?(label)
      option_not_offered?(root_element, label)
    end

    # True when +label+ is the selected option.
    def has_selected?(label)
      selected_option?(root_element, label)
    end

    # Waits until +label+ is no longer the selected option.
    def has_no_selected?(label)
      root_element.has_no_select?(selected: label, visible: :all)
    end

    # True when the control is disabled.
    def has_disabled?
      tom_select?(root_element) ? has_css?(sel(:tom_select_disabled)) : has_css?("select[disabled]", visible: :all)
    end

    # Waits until the control is enabled.
    def has_no_disabled?
      tom_select?(root_element) ? has_no_css?(sel(:tom_select_disabled)) : has_no_css?("select[disabled]", visible: :all)
    end

    # True when the control shows +label+ as chosen. Tom Select: the rendered
    # item, before any submit; plain <select>: the selected option.
    def has_item?(label)
      tom_select?(root_element) ? has_css?(sel(:tom_select_item), exact_text: label) : has_selected?(label)
    end

    # Waits until the control no longer shows +label+ as chosen.
    def has_no_item?(label)
      tom_select?(root_element) ? has_no_css?(sel(:tom_select_item), exact_text: label) : has_no_selected?(label)
    end

    # The Tom Select placeholder text.
    # @return [String, nil]
    def placeholder
      require_tom_select!(root_element, :placeholder)
      find(sel(:tom_select_placeholder), visible: :all)[:placeholder]
    end
  end
end
