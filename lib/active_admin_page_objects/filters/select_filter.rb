# frozen_string_literal: true

module ActiveAdminPageObjects
  # A select filter. Drives a native <select> through SelectControl, which a
  # gem rendering a JS select widget can prepend into.
  class SelectFilter < Filter
    include SelectControl

    # Chooses the option labelled +label+.
    def select_option(label)
      choose_option(root_element, label)
    end

    # True when the control offers +label+.
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
      not_selected_option?(root_element, label)
    end

    # True when the control is disabled.
    def has_disabled?
      control_disabled?(root_element)
    end

    # Waits until the control is enabled.
    def has_no_disabled?
      control_enabled?(root_element)
    end

    # True when the control shows +label+ as chosen.
    def has_item?(label)
      chosen_item?(root_element, label)
    end

    # Waits until the control no longer shows +label+ as chosen.
    def has_no_item?(label)
      no_chosen_item?(root_element, label)
    end
  end
end
