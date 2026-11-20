# frozen_string_literal: true

module ActiveAdminPageObjects
  # The action items (buttons and links) right of the page title. The button
  # of a `dropdown_menu` is an item too; #dropdown reaches the menu's own items.
  class ActionItems < Section
    selector_key :action_items

    elements :items, :active_admin, :action_item

    # The item labels in document order.
    # @return [Array<String>]
    def labels
      items.map { |item| item.text.strip }
    end

    # Clicks the item labelled +label+ (case-insensitive).
    def click(label)
      item(label).click
    end

    # True when an item labelled +label+ is shown.
    def has_item?(label, **options)
      eventually(**options) { find_item(label) }
    end

    # Waits until no item labelled +label+ is shown.
    def has_no_item?(label, **options)
      eventually(**options) { find_item(label).nil? }
    end

    # The dropdown menu whose button is labelled +label+ (case-insensitive),
    # or the only one when +label+ is nil.
    # @return [DropdownMenu]
    def dropdown(label = nil)
      DropdownMenu.new(self, label.nil? ? find(:active_admin, :action_item_dropdown) : dropdown_node(label))
    end

    private

    def dropdown_node(label)
      root_element.synchronize do
        all(:active_admin, :action_item_dropdown, wait: false).find do |menu|
          same_text?(menu.find(:active_admin, :dropdown_menu_button, wait: false).text, label)
        end || raise(Capybara::ElementNotFound, "no action item dropdown #{label.inspect}")
      end
    end

    def item(label)
      find_item(label) || raise(Capybara::ElementNotFound, "no action item #{label.inspect} in #{labels.inspect}")
    end

    def find_item(label)
      items.find { |el| same_text?(el.text, label) }
    end
  end
end
