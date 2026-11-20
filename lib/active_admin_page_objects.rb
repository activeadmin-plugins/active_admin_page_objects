# frozen_string_literal: true

require "capybara"
require "site_prism"

require_relative "active_admin_page_objects/version"
require_relative "active_admin_page_objects/errors"
require_relative "active_admin_page_objects/selectors"
require_relative "active_admin_page_objects/text"

# SitePrism pages and sections for ActiveAdmin. See README.md.
module ActiveAdminPageObjects
  extend Text

  # Raises unless the loaded gem satisfies +requirements+. Plugins call it when
  # their page objects load, e.g. `check_version!(">= 1.0.0.a", "< 2", plugin: "my_plugin")`.
  def self.check_version!(*requirements, plugin:)
    return if Gem::Requirement.new(*requirements).satisfied_by?(Gem::Version.new(VERSION))

    raise IncompatibleVersion,
          "#{plugin} page objects need active_admin_page_objects #{requirements.join(', ')}, but #{VERSION} is loaded"
  end
end

# `find(:active_admin, :table)` resolves the CSS when the query runs, so
# selectors that a theme or plugin registers later still apply.
Capybara.add_selector(:active_admin) do
  css { |key| ActiveAdminPageObjects.selector(key) }
end

# `find(:active_admin_panel, "Notes")` finds the panel whose title is "Notes",
# ignoring case and surrounding whitespace. `:active_admin_sidebar` does the
# same for sidebar sections, which `:active_admin_panel` leaves out.
{
  active_admin_panel: %i[panel panel_title],
  active_admin_sidebar: %i[sidebar_section sidebar_title]
}.each do |name, (container_key, title_key)|
  Capybara.add_selector(name) do
    css { |_title| ActiveAdminPageObjects.selector(container_key) }
    locator_filter do |node, title|
      next true if title.nil?

      # The first heading is the container's own; later ones belong to its body.
      heading = node.first(:css, ActiveAdminPageObjects.selector(title_key), visible: :all, minimum: 0, wait: false)
      !heading.nil? && ActiveAdminPageObjects.same_text?(heading.text(:all), title)
    end
  end
end

require_relative "active_admin_page_objects/section"
require_relative "active_admin_page_objects/select_control"
require_relative "active_admin_page_objects/status_tag"
require_relative "active_admin_page_objects/panel"
require_relative "active_admin_page_objects/sidebar"
require_relative "active_admin_page_objects/modal_dialog"
require_relative "active_admin_page_objects/has_many"
require_relative "active_admin_page_objects/comments"
require_relative "active_admin_page_objects/utility_navigation"
require_relative "active_admin_page_objects/dropdown_menu"
require_relative "active_admin_page_objects/breadcrumbs"
require_relative "active_admin_page_objects/action_items"
require_relative "active_admin_page_objects/flashes"
require_relative "active_admin_page_objects/main_menu"
require_relative "active_admin_page_objects/layout"
require_relative "active_admin_page_objects/page"
require_relative "active_admin_page_objects/table"
require_relative "active_admin_page_objects/attributes_table"
require_relative "active_admin_page_objects/filters"
require_relative "active_admin_page_objects/filters_footer"
require_relative "active_admin_page_objects/scopes"
require_relative "active_admin_page_objects/pagination"
require_relative "active_admin_page_objects/batch_actions"
require_relative "active_admin_page_objects/form"
require_relative "active_admin_page_objects/tabs"
