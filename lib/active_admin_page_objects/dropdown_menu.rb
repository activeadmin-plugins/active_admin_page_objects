# frozen_string_literal: true

module ActiveAdminPageObjects
  # A `dropdown_menu` among the action items. Reached with
  # `page.action_items.dropdown("More")`.
  class DropdownMenu < Section
    selector_key :action_item_dropdown

    # The button text.
    # @return [String]
    def label
      find(:active_admin, :dropdown_menu_button).text.strip
    end

    # Opens the menu unless it is open. The button toggles the menu, so the
    # list's visibility is checked first; without JavaScript the list is
    # always shown.
    def open
      button = find(:active_admin, :dropdown_menu_button)
      unless has_css?(sel(:dropdown_menu_list), wait: false)
        button.click
        find(:active_admin, :dropdown_menu_list)
      end
      self
    end

    # The item labels in document order, read from a closed menu too.
    # @return [Array<String>]
    def labels
      items.map { |item| item.text(:all).strip }
    end

    # Opens the menu and clicks the item labelled +label+ (case-insensitive).
    def click(label)
      open
      item(label).click
    end

    # True when the menu has an item labelled +label+.
    def has_item?(label, **options)
      eventually(**options) { find_item(label) }
    end

    # Waits until the menu has no item labelled +label+.
    def has_no_item?(label, **options)
      eventually(**options) { find_item(label).nil? }
    end

    private

    def items
      all(:active_admin, :dropdown_menu_item, visible: :all, wait: false)
    end

    def item(label)
      find_item(label) || raise(Capybara::ElementNotFound, "no dropdown item #{label.inspect} in #{labels.inspect}")
    end

    def find_item(label)
      items.find { |el| same_text?(el.text(:all), label) }
    end
  end
end
