# frozen_string_literal: true

module ActiveAdminPageObjects
  # Include into a SitePrism::Page for pages rendered in the ActiveAdmin
  # layout. Each element and section also gets SitePrism's `has_<name>?` and
  # `has_no_<name>?` predicates.
  module Layout
    # Element name => selector-map key. ActiveAdmin 3 has no dark mode toggle
    # and no user menu button: using those elements raises NotInActiveAdmin3.
    ELEMENTS = {
      site_title: :site_title,
      dark_mode_toggle: :dark_mode_toggle,
      theme_switcher: :dark_mode_toggle,
      user_menu_button: :user_menu_button,
      page_title: :page_title,
      blank_slate: :blank_slate
    }.freeze

    class << self
      # Registered elements: name => find arguments.
      # @return [Hash{Symbol => Array}]
      def elements
        @elements ||= ELEMENTS.to_h { |name, key| [name, [:active_admin, key]] }
      end

      # Registered sections: name => [section class, *find arguments].
      # @return [Hash{Symbol => Array}]
      def sections
        @sections ||= {
          breadcrumbs: [Breadcrumbs],
          action_items: [ActionItems],
          flashes: [Flashes],
          main_menu: [MainMenu],
          modal_dialog: [ModalDialog]
        }
      end

      # The classes that included Layout.
      # @return [Array<Class>]
      def includers
        @includers ||= []
      end

      def included(base)
        includers << base
        elements.each { |name, args| base.element(name, *args) }
        sections.each { |name, (klass, *args)| base.section(name, klass, *args) }
      end

      # Registers an element and declares it on every page that included
      # Layout, including ones defined before the call. Re-adding a name
      # replaces it.
      def add_element(name, *find_args)
        elements[name] = find_args
        includers.each { |base| base.element(name, *find_args) }
      end

      # Registers a section and declares it on every page that included
      # Layout, including ones defined before the call. Re-adding a name
      # replaces it. For example:
      #   ActiveAdminPageObjects::Layout.add_section(:tabs_bar, MyTheme::TabsBar)
      def add_section(name, klass, *find_args)
        sections[name] = [klass, *find_args]
        includers.each { |base| base.section(name, klass, *find_args) }
      end
    end

    # The panel titled +title+: a String (case-insensitive) or a Regexp.
    # Sidebar sections and the comments panel are not panels here: use
    # #sidebar and Comments.
    # @return [Panel]
    def panel(title)
      Panel.new(self, find(:active_admin_panel, title))
    end

    # The sidebar section titled +title+: a String (case-insensitive) or a Regexp.
    # @return [Sidebar]
    def sidebar(title)
      Sidebar.new(self, find(:active_admin_sidebar, title))
    end

    # The utility navigation in the header: the current user and the logout link.
    # @return [UtilityNavigation]
    def utility_navigation
      UtilityNavigation.new(self, find(:active_admin, :utility_navigation))
    end
  end
end
