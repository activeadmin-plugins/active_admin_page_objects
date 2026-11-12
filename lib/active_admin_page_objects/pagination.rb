# frozen_string_literal: true

module ActiveAdminPageObjects
  # The pagination links under the index table. ActiveAdmin renders them only
  # when there is more than one page.
  class Pagination < Section
    selector_key :pagination

    # Clicks the link to page +page+.
    def go_to(page)
      find("a", exact_text: page.to_s).click
    end

    # Clicks the "next page" arrow.
    def next_page
      find(:active_admin, :pagination_next).click
    end

    # Clicks the "previous page" arrow.
    def previous_page
      find(:active_admin, :pagination_previous).click
    end

    # The current page number.
    # @return [Integer]
    def current_page
      Integer(find(:active_admin, :pagination_current).text.strip)
    end

    # True when page +page+ is the current one.
    def has_current_page?(page, **options)
      has_css?(sel(:pagination_current), exact_text: page.to_s, **options)
    end

    # Waits until page +page+ is no longer the current one.
    def has_no_current_page?(page, **options)
      has_no_css?(sel(:pagination_current), exact_text: page.to_s, **options)
    end
  end
end
