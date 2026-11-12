# frozen_string_literal: true

module ActiveAdminPageObjects
  # The filter form buttons. Filters#submit and Filters#clear do the same.
  class FiltersFooter < Section
    selector_key :filters_footer

    # Clicks the "Filter" button.
    def submit
      find(:active_admin, :filters_submit).click
    end

    # Clicks "Clear Filters".
    def clear
      find(:active_admin, :filters_clear).click
    end
  end
end
