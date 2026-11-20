# frozen_string_literal: true

module ActiveAdminPageObjects
  # The utility navigation in the header: the current user and the logout
  # link. Reached with `page.utility_navigation`.
  class UtilityNavigation < Section
    selector_key :utility_navigation

    # The item texts in document order.
    # @return [Array<String>]
    def labels
      all(:active_admin, :utility_navigation_item).map { |item| item.text.strip }
    end

    # The current user's display name.
    # @return [String]
    def current_user
      find(:active_admin, :utility_navigation_current_user).text.strip
    end

    # Clicks the logout link.
    def logout
      find(:active_admin, :utility_navigation_logout).click
    end
  end
end
