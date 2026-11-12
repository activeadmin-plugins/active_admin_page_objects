# frozen_string_literal: true

require "capybara"
require "site_prism"

require_relative "active_admin_page_objects/version"
require_relative "active_admin_page_objects/errors"
require_relative "active_admin_page_objects/markup"
require_relative "active_admin_page_objects/selectors"
require_relative "active_admin_page_objects/text"

# SitePrism pages and sections for ActiveAdmin. See README.md.
module ActiveAdminPageObjects
  extend Markup
  extend Text

  # Raises unless the loaded gem satisfies +requirements+. Plugins call it when
  # their page objects load, e.g. `check_version!("~> 0.1", plugin: "my_plugin")`.
  def self.check_version!(*requirements, plugin:)
    return if Gem::Requirement.new(*requirements).satisfied_by?(Gem::Version.new(VERSION))

    raise IncompatibleVersion,
          "#{plugin} page objects need active_admin_page_objects #{requirements.join(', ')}, but #{VERSION} is loaded"
  end
end

# `find(:active_admin, :table)` resolves the CSS for the current markup when the
# query runs, so the gem can be required before ActiveAdmin is loaded.
Capybara.add_selector(:active_admin) do
  css { |key| ActiveAdminPageObjects.selector(key) }
end

# `find(:active_admin_panel, "Notes")` finds the panel whose title is "Notes",
# ignoring case and surrounding whitespace.
Capybara.add_selector(:active_admin_panel) do
  css { |_title| ActiveAdminPageObjects.selector(:panel) }
  locator_filter do |node, title|
    next true if title.nil?

    titles = node.all(:css, ActiveAdminPageObjects.selector(:panel_title), visible: :all, wait: false)
    titles.any? { |el| ActiveAdminPageObjects.same_text?(el.text(:all), title) }
  end
end

require_relative "active_admin_page_objects/section"
require_relative "active_admin_page_objects/select_control"
require_relative "active_admin_page_objects/breadcrumbs"
require_relative "active_admin_page_objects/action_items"
require_relative "active_admin_page_objects/flashes"
require_relative "active_admin_page_objects/main_menu"
require_relative "active_admin_page_objects/layout"
require_relative "active_admin_page_objects/page"
require_relative "active_admin_page_objects/table"
require_relative "active_admin_page_objects/attributes_table"
require_relative "active_admin_page_objects/panel"
require_relative "active_admin_page_objects/filters"
require_relative "active_admin_page_objects/filters_footer"
require_relative "active_admin_page_objects/scopes"
require_relative "active_admin_page_objects/pagination"
require_relative "active_admin_page_objects/batch_actions"
require_relative "active_admin_page_objects/form"
require_relative "active_admin_page_objects/tabs"
