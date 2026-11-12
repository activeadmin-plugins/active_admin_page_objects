# frozen_string_literal: true

module ActiveAdminPageObjects
  # Include into a SitePrism::Page for pages rendered in the ActiveAdmin
  # layout. Each element and section also gets SitePrism's `has_<name>?` and
  # `has_no_<name>?` predicates.
  module Layout
    # Element name => selector-map key.
    ELEMENTS = {
      site_title: :site_title,
      dark_mode_toggle: :dark_mode_toggle,
      theme_switcher: :dark_mode_toggle,
      user_menu_button: :user_menu_button,
      page_title: :page_title,
      blank_slate: :blank_slate
    }.freeze

    def self.included(base)
      ELEMENTS.each { |name, key| base.element(name, :active_admin, key) }
      base.section :breadcrumbs, Breadcrumbs
      base.section :action_items, ActionItems
      base.section :flashes, Flashes
      base.section :main_menu, MainMenu
    end

    # The panel titled +title+ (case-insensitive).
    # @return [Panel]
    def panel(title)
      Panel.new(self, find(:active_admin_panel, title))
    end

    # The utility navigation of ActiveAdmin 3.
    # @raise [RemovedInActiveAdmin4] on ActiveAdmin 4
    def utility_navigation
      find(:active_admin, :utility_navigation)
    end
  end
end
