# frozen_string_literal: true

module ActiveAdminPageObjects
  # The batch-action form around the index table. Needs a JavaScript driver:
  # ActiveAdmin's JavaScript enables the menu once a row is selected, and
  # submits the form.
  class BatchActions < Section
    selector_key :batch_actions

    # Ticks the "select all" checkbox in the table header.
    def select_all
      find(:active_admin, :batch_actions_toggle_all).check
    end

    # Opens the batch-action menu and runs the action labelled +label+
    # ("Delete Selected"), or with the batch-action name (`:destroy`).
    #
    # An action with a `confirm:` or a `form:` opens ActiveAdmin's modal
    # dialog instead of submitting. #apply then sets each of +inputs+ in the
    # dialog by field name (`status: "pending"` picks the option of a select,
    # or types into an input) and clicks OK.
    def apply(label, inputs = {})
      button = find(:active_admin, :batch_actions_button)
      # The button toggles the menu, so leave an open menu open.
      button.click unless has_css?(sel(:batch_actions_menu), wait: false)
      item = action_item(label)
      opens_dialog = !item[:"data-confirm"].to_s.empty?
      item.click
      confirm_dialog(inputs) if opens_dialog
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

    # The dialog is appended to <body>, outside this section.
    def confirm_dialog(inputs)
      dialog = ModalDialog.new(self, capybara_session.find(:active_admin, :modal_dialog))
      inputs.each { |name, value| dialog.fill(name, with: value) }
      dialog.confirm
    end

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
