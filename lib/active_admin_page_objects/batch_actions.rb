# frozen_string_literal: true

module ActiveAdminPageObjects
  # The batch-action form around the index table. Needs a JavaScript driver:
  # ActiveAdmin's JavaScript enables the menu and submits the form.
  class BatchActions < Section
    selector_key :batch_actions

    # Ticks the "select all" checkbox in the table header.
    def select_all
      find(:active_admin, :batch_actions_toggle_all).check
    end

    # Opens the batch-action menu and runs the action labelled +label+
    # ("Delete Selected"), or with the batch-action name (`:destroy`). Accepts
    # the browser confirmation when the action has one.
    def apply(label)
      find(:active_admin, :batch_actions_button).click
      item = action_item(label)
      if item[:"data-confirm"].to_s.empty?
        item.click
      else
        accept_confirm(item[:"data-confirm"]) { item.click }
      end
    end

    # True when the menu has an action labelled +label+ or named +label+.
    def has_action?(label, **options)
      eventually(**options) { find_action_item(label) }
    end

    # Waits until the menu has no such action.
    def has_no_action?(label, **options)
      eventually(**options) { find_action_item(label).nil? }
    end

    private

    def action_items
      all(:active_admin, :batch_action_item, visible: :all, wait: false)
    end

    def find_action_item(label)
      action_items.find do |item|
        label.is_a?(Symbol) ? item[:"data-action"] == label.to_s : same_text?(item.text(:all), label)
      end
    end

    def action_item(label)
      root_element.synchronize { find_action_item(label) || raise(Capybara::ElementNotFound, "no batch action #{label.inspect}") }
    end
  end
end
