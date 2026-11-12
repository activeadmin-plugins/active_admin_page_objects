# frozen_string_literal: true

module ActiveAdminPageObjects
  # Marks a selector-map entry for a feature that ActiveAdmin 4 removed.
  REMOVED = Object.new.freeze

  # One CSS selector map per markup. A `%s` in a selector is filled from the
  # arguments of ActiveAdminPageObjects.selector.
  module Selectors
    V4 = {
      site_title: "h1[data-test-site-title]",
      dark_mode_toggle: "button.dark-mode-toggle",
      user_menu_button: "#user-menu-button",
      page_title: "[data-test-page-header] h2",
      utility_navigation: REMOVED,

      breadcrumbs: 'nav[aria-label="breadcrumb"]',
      breadcrumb_link: "ol > li > a",

      action_items: "[data-test-action-items]",
      action_item: "a, button",
      action_item_dropdown: REMOVED,

      flashes: "[data-test-page-header] + div:not([data-test-page-content])",
      flash: "div",
      flash_notice: "div.bg-green-50",
      flash_alert: "div.bg-yellow-50",
      flash_error: "div.bg-red-50",

      main_menu: "#main-menu",
      main_menu_selected: "a.selected",

      table: "table.data-table",
      table_header: "thead th",
      table_row: "tbody > tr",
      table_row_by_id: 'tbody > tr[id$="_%s"]',
      table_cell: 'td[data-column="%s"]',
      table_row_checkbox: "input.batch-actions-resource-selection",
      blank_slate: ".main-content-container .border-dashed",

      attributes_table: ".attributes-table",
      attributes_table_row: 'tr[data-row="%s"]',

      panel: ".panel",
      panel_title: ".panel-title",
      panel_body: ".panel-body",

      filters: "form.filters-form",
      filter: "#q_%s_input",
      filter_predicate: "select[data-search-methods]",
      filter_value: ".filters-form-input-group > input",
      filter_range_from: 'input[name$="_gteq]"]',
      filter_range_to: 'input[name$="_lteq]"]',
      filters_footer: ".filters-form-buttons",
      filters_submit: ".filters-form-submit",
      filters_clear: ".filters-form-clear",

      scopes: ".scopes",
      scope: "a.index-button",
      scope_selected: "a.index-button-selected",
      scope_count: ".scopes-count",

      pagination: "nav[data-test-pagination]",
      pagination_current: "a.bg-blue-500",
      pagination_next: 'a[rel="next"]:has(.sr-only)',
      pagination_previous: 'a[rel="prev"]:has(.sr-only)',

      batch_actions: "form#collection_selection",
      batch_actions_toggle_all: "input.batch-actions-toggle-all",
      batch_actions_button: ".batch-actions-dropdown-toggle",
      batch_action_item: "[data-batch-action-item]",

      form: "form.formtastic",
      form_input: "li#%s_%s_input",
      form_inline_error: ".inline-errors",
      form_semantic_error: "ul.errors > li",
      form_submit: "fieldset.actions input[type=submit], fieldset.actions button[type=submit]",

      tabs: REMOVED,

      tom_select: ".ts-wrapper",
      tom_select_control: ".ts-control",
      tom_select_dropdown: ".ts-dropdown",
      tom_select_option: ".option",
      tom_select_create: ".create",
      tom_select_search: ".dropdown-input",
      tom_select_item: ".ts-control .item",
      tom_select_placeholder: ".items-placeholder",
      tom_select_disabled: ".ts-wrapper.disabled"
    }.freeze

    # Theme v4 entries override V4 one by one; missing keys fall back to V4.
    THEME_V4 = {}.freeze

    # The maps in use: the defaults plus ActiveAdminPageObjects.register_selectors.
    MAPS = { v4: V4.dup, theme_v4: THEME_V4.dup }.freeze
    FALLBACKS = { theme_v4: :v4 }.freeze
  end

  class << self
    # The CSS selector for +key+ under the current markup.
    # @raise [UnsupportedMarkup] for ActiveAdmin 3 markup
    # @raise [RemovedInActiveAdmin4] when ActiveAdmin 4 removed the feature
    # @return [String]
    def selector(key, *args)
      css = lookup_selector(markup, key)
      raise RemovedInActiveAdmin4, "#{key.to_s.tr('_', ' ')} was removed in ActiveAdmin 4" if css.equal?(REMOVED)

      args.empty? ? css : format(css, *args)
    end

    # Adds or overrides selectors for +markup+, e.g. for a plugin's sections.
    def register_selectors(markup, **map)
      raise ArgumentError, "unknown markup #{markup.inspect}" unless Selectors::MAPS.key?(markup)

      Selectors::MAPS[markup].merge!(map)
    end

    private

    def lookup_selector(markup, key)
      if markup == :v3
        raise UnsupportedMarkup,
              "ActiveAdmin 3 markup is not supported yet by active_admin_page_objects #{VERSION}"
      end

      map = Selectors::MAPS.fetch(markup)
      return map[key] if map.key?(key)

      fallback = Selectors::FALLBACKS[markup]
      return lookup_selector(fallback, key) if fallback

      raise KeyError, "no #{markup} selector for #{key.inspect}"
    end
  end
end
