# frozen_string_literal: true

module ActiveAdminPageObjects
  # Marks a selector-map entry for a feature that ActiveAdmin 4 removed. Kept
  # so code written for 2.x still loads; no 1.x entry uses it.
  REMOVED = Object.new.freeze

  # Marks a selector-map entry for a feature that ActiveAdmin 3 does not have.
  NOT_IN_ACTIVE_ADMIN_3 = Object.new.freeze

  # The CSS selector map for vanilla ActiveAdmin 3. A `%s` in a selector is
  # filled from the arguments of ActiveAdminPageObjects.selector.
  module Selectors
    DEFAULTS = {
      site_title: "#site_title",
      dark_mode_toggle: NOT_IN_ACTIVE_ADMIN_3,
      user_menu_button: NOT_IN_ACTIVE_ADMIN_3,
      page_title: "#page_title",

      utility_navigation: "#utility_nav",
      utility_navigation_item: "li",
      utility_navigation_current_user: "#current_user",
      utility_navigation_logout: "#logout a",

      breadcrumbs: "#titlebar_left .breadcrumb",
      breadcrumb_link: "a",

      # Rendered on every page, also without items.
      action_items: "#titlebar_right .action_items",
      action_item: ".action_item > a, .action_item > button, .action_item > .dropdown_menu > .dropdown_menu_button",
      action_item_dropdown: ".action_item .dropdown_menu",

      dropdown_menu_button: "a.dropdown_menu_button",
      dropdown_menu_list: ".dropdown_menu_list_wrapper",
      dropdown_menu_item: ".dropdown_menu_list a",

      # Rendered on every page, also without flashes.
      flashes: ".flashes",
      flash: ".flash",
      flash_notice: ".flash.flash_notice",
      flash_alert: ".flash.flash_alert",
      flash_error: ".flash.flash_error",
      flash_warning: ".flash.flash_warning",

      main_menu: "#header #tabs",
      main_menu_selected: "li.current",

      table: "table.index_table",
      table_header: "thead th.col",
      table_column_header: "thead th.col-%s",
      table_sortable_header: "thead th.sortable.col-%s",
      table_sorted_header: "thead th.sorted-asc, thead th.sorted-desc",
      table_sort_link: "a",
      table_row: "tbody > tr",
      table_row_by_id: 'tbody > tr[id$="_%s"]',
      table_cell: "td.col-%s",
      table_row_checkbox: "input.collection_selection",
      blank_slate: ".blank_slate_container",

      attributes_table: ".attributes_table",
      attributes_table_row: "tr.row-%s",
      attributes_table_rows: "tr[class*='row-']",

      status_tag: ".status_tag",

      # Sidebar sections and the comments panel are panels too in ActiveAdmin 3;
      # they have their own sections, so `panel` leaves them out.
      panel: ".panel:not(.sidebar_section):not(.comments)",
      panel_title: "h3",
      panel_body: ".panel_contents",

      sidebar: "#sidebar",
      sidebar_section: "#sidebar .sidebar_section",
      sidebar_title: "h3",
      sidebar_body: ".panel_contents",

      filters: "#filters_sidebar_section form.filter_form",
      filter: "#q_%s_input",
      filter_wrappers: ".filter_form_field",
      filter_predicate: "select",
      filter_value: "input",
      filter_range_from: 'input[name*="_gteq"]',
      filter_range_to: 'input[name*="_lteq"]',
      filters_footer: "form.filter_form .buttons",
      filters_submit: "input[type=submit]",
      filters_clear: "a.clear_filters_btn",

      scopes: ".scopes",
      scope: ".table_tools_segmented_control li.scope > a",
      scope_selected: ".table_tools_segmented_control li.scope.selected > a",
      scope_count: "span.count",

      pagination: "#index_footer .pagination",
      pagination_current: ".page.current",
      pagination_next: ".next a",
      pagination_previous: ".prev a",

      download_links: "#index_footer .download_links",
      download_link: "a",

      batch_actions: "form#collection_selection",
      batch_actions_toggle_all: "#collection_selection_toggle_all",
      batch_actions_button: ".batch_actions_selector a.dropdown_menu_button",
      batch_actions_menu: ".batch_actions_selector .dropdown_menu_list_wrapper",
      batch_action_item: ".batch_actions_selector a.batch_action[data-action]",

      modal_dialog: ".active_admin_dialog",
      modal_dialog_title: ".ui-dialog-title",
      modal_dialog_form: "form#dialog_confirm",
      modal_dialog_ok: ".ui-dialog-buttonset button:nth-child(1)",
      modal_dialog_cancel: ".ui-dialog-buttonset button:nth-child(2)",

      form: "form.formtastic:not(.active_admin_comment)",
      # Hidden inputs and the delete checkbox of a has_many fieldset are not fields.
      form_input_wrapper: "li.input:not(.hidden):not(.has_many_delete)",
      form_input: "li#%s_%s_input",
      form_choice: "li.choice label",
      # The hidden input of a boolean or check_boxes wrapper is not a control.
      form_control: "input:not([type=hidden]), select, textarea",
      form_inline_error: "p.inline-errors",
      form_semantic_error: "ul.errors > li",
      form_submit: "fieldset.actions input[type=submit], fieldset.actions button[type=submit]",

      has_many_container: ".has_many_container",
      has_many: ".has_many_container.%s",
      has_many_heading: "h3",
      has_many_fieldset: "fieldset.has_many_fields",
      has_many_add: "a.has_many_add",
      has_many_remove: "a.has_many_remove",
      has_many_delete: "li.has_many_delete input[type=checkbox]",

      # `ul#tabs` (the main menu) and `ul#utility_nav` carry the `tabs` class too.
      tabs: "#active_admin_content .tabs",
      tab_link: ".nav-tabs > li > a",
      tab_current_link: ".nav-tabs > li.ui-tabs-active > a",
      tab_panel: ".tab-content > div",

      comments: '[id^="active_admin_comments_for_"]',
      comments_title: "h3",
      # The comment form carries the `active_admin_comment` class too.
      comment: "div.active_admin_comment",
      comment_body: ".active_admin_comment_body",
      comment_author: ".active_admin_comment_author",
      comment_delete: '.active_admin_comment_meta a[data-method="delete"]',
      comment_input: "#active_admin_comment_body",
      comment_submit: "form.active_admin_comment input[type=submit]"
    }.freeze

    # The map in use: DEFAULTS plus ActiveAdminPageObjects.register_selectors.
    MAP = DEFAULTS.dup
  end

  class << self
    # The CSS selector for +key+.
    # @raise [NotInActiveAdmin3] when ActiveAdmin 3 does not have the feature
    # @raise [KeyError] when no selector is registered for +key+
    # @return [String]
    def selector(key, *args)
      css = Selectors::MAP.fetch(key) { raise KeyError, "no selector for #{key.inspect}" }
      raise NotInActiveAdmin3, "#{key.to_s.tr('_', ' ')} is not in ActiveAdmin 3" if css.equal?(NOT_IN_ACTIVE_ADMIN_3)

      args.empty? ? css : format(css, *args)
    end

    # Adds or overrides selectors, e.g. for a theme's or plugin's sections.
    def register_selectors(**map)
      Selectors::MAP.merge!(map)
    end
  end
end
