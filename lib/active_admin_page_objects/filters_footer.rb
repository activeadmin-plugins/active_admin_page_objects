# frozen_string_literal: true

module ActiveAdminPageObjects
  # The filter form buttons: `submit` and `clear`, as on Filters.
  class FiltersFooter < Section
    include Filters::Buttons

    selector_key :filters_footer
  end
end
