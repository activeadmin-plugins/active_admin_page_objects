# frozen_string_literal: true

module ActiveAdminPageObjects
  # Marks a selector-map entry for a feature that ActiveAdmin 4 removed.
  REMOVED = Object.new.freeze

  # The CSS selector map for vanilla ActiveAdmin 4. A `%s` in a selector is
  # filled from the arguments of ActiveAdminPageObjects.selector.
  module Selectors
    DEFAULTS = {
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
      table_column_header: 'thead th[data-column="%s"]',
      table_row: "tbody > tr",
      table_row_by_id: 'tbody > tr[id$="_%s"]',
      table_cell: 'td[data-column="%s"]',
      table_row_checkbox: "input.batch-actions-resource-selection",
      # The cells of the actions column at a 1-based column position.
      table_actions_cell: "tbody > tr > td:nth-child(%s) .data-table-resource-actions",
      table_row_actions_cell: "td:has(.data-table-resource-actions)",
      blank_slate: ".main-content-container .border-dashed",

      attributes_table: ".attributes-table",
      attributes_table_row: 'tr[data-row="%s"]',
      attributes_table_rows: "tr[data-row]",

      panel: ".panel",
      panel_title: ".panel-title",
      panel_body: ".panel-body",

      filters: "form.filters-form",
      filter: "#q_%s_input",
      filter_wrappers: ".filters-form-field",
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

      download_links: ".paginated-collection-footer > div:has(> a)",
      download_link: "a",

      batch_actions: "form#collection_selection",
      batch_actions_toggle_all: "input.batch-actions-toggle-all",
      batch_actions_button: ".batch-actions-dropdown-toggle",
      batch_action_item: "[data-batch-action-item]",

      form: "form.formtastic",
      # Hidden inputs are not fields.
      form_input_wrapper: "li.input:not(.hidden)",
      form_input: "li#%s_%s_input",
      form_choice: "li.choice label",
      # The hidden input of a boolean or check_boxes wrapper is not a control.
      form_control: "input:not([type=hidden]), select, textarea",
      form_inline_error: ".inline-errors",
      form_semantic_error: "ul.errors > li",
      form_submit: "fieldset.actions input[type=submit], fieldset.actions button[type=submit]",

      tabs: REMOVED
    }.freeze

    # The map in use: DEFAULTS plus ActiveAdminPageObjects.register_selectors.
    MAP = DEFAULTS.dup
  end

  class << self
    # The CSS selector for +key+.
    # @raise [RemovedInActiveAdmin4] when ActiveAdmin 4 removed the feature
    # @raise [KeyError] when no selector is registered for +key+
    # @return [String]
    def selector(key, *args)
      css = Selectors::MAP.fetch(key) { raise KeyError, "no selector for #{key.inspect}" }
      raise RemovedInActiveAdmin4, "#{key.to_s.tr('_', ' ')} was removed in ActiveAdmin 4" if css.equal?(REMOVED)

      args.empty? ? css : format(css, *args)
    end

    # Adds or overrides selectors, e.g. for a theme's or plugin's sections.
    def register_selectors(**map)
      Selectors::MAP.merge!(map)
    end
  end
end
