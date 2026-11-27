# frozen_string_literal: true

require "capybara"
require "site_prism"

require_relative "active_admin_page_objects/version"
require_relative "active_admin_page_objects/errors"
require_relative "active_admin_page_objects/selectors"
require_relative "active_admin_page_objects/text"
require_relative "active_admin_page_objects/input_classes"

# SitePrism pages and sections for ActiveAdmin. See README.md.
module ActiveAdminPageObjects
  extend Text

  # Raises unless the loaded gem satisfies +requirements+. Plugins call it when
  # their page objects load, e.g. `check_version!(">= 2.0.0.a", "< 3.0.0.a", plugin: "my_plugin")`.
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
# ignoring case and surrounding whitespace. A Regexp title matches the title
# text instead: `find(:active_admin_panel, /\ARoutes \(\d+\)\z/)`.
Capybara.add_selector(:active_admin_panel) do
  css { |_title| ActiveAdminPageObjects.selector(:panel) }
  locator_filter do |node, title|
    next true if title.nil?

    # The panel's own title comes before the titles of panels nested in its body.
    own = node.first(:css, ActiveAdminPageObjects.selector(:panel_title), visible: :all, minimum: 0, wait: false)
    own && ActiveAdminPageObjects.text_match?(own.text(:all), title)
  end
end

require_relative "active_admin_page_objects/section"
require_relative "active_admin_page_objects/declarations"
require_relative "active_admin_page_objects/select_control"
require_relative "active_admin_page_objects/breadcrumbs"
require_relative "active_admin_page_objects/action_items"
require_relative "active_admin_page_objects/flashes"
require_relative "active_admin_page_objects/main_menu"
require_relative "active_admin_page_objects/layout"
require_relative "active_admin_page_objects/page"
require_relative "active_admin_page_objects/table/rows_by_cell"
require_relative "active_admin_page_objects/table"
require_relative "active_admin_page_objects/attributes_table"
require_relative "active_admin_page_objects/status_tag"
require_relative "active_admin_page_objects/panel"
require_relative "active_admin_page_objects/comments"
require_relative "active_admin_page_objects/filters"
require_relative "active_admin_page_objects/filters_footer"
require_relative "active_admin_page_objects/scopes"
require_relative "active_admin_page_objects/pagination"
require_relative "active_admin_page_objects/download_links"
require_relative "active_admin_page_objects/batch_actions"
require_relative "active_admin_page_objects/fields"
require_relative "active_admin_page_objects/form"
require_relative "active_admin_page_objects/has_many"
require_relative "active_admin_page_objects/tabs"
