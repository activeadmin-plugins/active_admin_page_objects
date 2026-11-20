# frozen_string_literal: true

module ActiveAdminPageObjects
  # The filter form buttons. Filters#submit and Filters#clear do the same.
  class FiltersFooter < Section
    selector_key :filters_footer

    # Clicks the "Filter" button.
    def submit
      find(:active_admin, :filters_submit).click
    end

    # Clicks "Clear Filters". ActiveAdmin 3 clears in JavaScript, so this
    # needs a JavaScript driver.
    def clear
      find(:active_admin, :filters_clear).click
    end
  end
end
