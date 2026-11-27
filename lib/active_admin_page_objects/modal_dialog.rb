# frozen_string_literal: true

module ActiveAdminPageObjects
  # The modal dialog ActiveAdmin opens for batch actions that ask to confirm or
  # for input. Needs a JavaScript driver. Reached with `page.modal_dialog`.
  class ModalDialog < Section
    selector_key :modal_dialog

    # The dialog title text.
    # @return [String]
    def title
      find(:active_admin, :modal_dialog_title).text.strip
    end

    # Sets the field named +name+: types into an input, or picks the option
    # labelled +with+ in a select.
    def fill(name, with:)
      field = find(:active_admin, :modal_dialog_form).find(:css, field_selector(name))
      if field.tag_name == "select"
        field.select(with.to_s)
      else
        field.set(with)
      end
    end

    # Clicks OK and waits until the dialog is gone.
    def confirm
      find(:active_admin, :modal_dialog_ok).click
      wait_until_gone
    end

    # Clicks Cancel and waits until the dialog is gone.
    def cancel
      find(:active_admin, :modal_dialog_cancel).click
      wait_until_gone
    end

    # True when the dialog form has a field named +name+.
    def has_field?(name, **options)
      has_css?("#{sel(:modal_dialog_form)} #{field_selector(name)}", **options)
    end

    # Waits until the dialog form has no field named +name+.
    def has_no_field?(name, **options)
      has_no_css?("#{sel(:modal_dialog_form)} #{field_selector(name)}", **options)
    end

    private

    def field_selector(name)
      format('[name="%s"]', name)
    end

    # The root element is stale once the dialog closes, so ask the session.
    def wait_until_gone
      root_element.session.assert_no_selector(:css, sel(:modal_dialog))
    end
  end
end
