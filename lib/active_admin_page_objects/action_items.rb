# frozen_string_literal: true

module ActiveAdminPageObjects
  # The action items (buttons and links) right of the page title.
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

    # The action-item dropdown of ActiveAdmin 3.
    # @raise [RemovedInActiveAdmin4] on ActiveAdmin 4
    def dropdown(*)
      find(:active_admin, :action_item_dropdown)
    end

    private

    def item(label)
      find_item(label) || raise(Capybara::ElementNotFound, "no action item #{label.inspect} in #{labels.inspect}")
    end

    def find_item(label)
      items.find { |el| same_text?(el.text, label) }
    end
  end
end
