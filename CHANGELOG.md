# Changelog

## Unreleased

### Added

- Declared labels: `AttributesTable.row(key, label)`, `Table.column(key, label)`, `Filters.filter(key, label, type = nil)` and `Form.field(key, label, type = nil)` declare a section's keys and labels, also inside a `section ... do` block. `have_declared_rows`, `have_declared_columns`, `have_declared_filters` and `have_declared_fields` compare the labels with the page exactly. `declared_label_mismatches` returns the labels that differ.
- A section with declarations raises `ArgumentError` for an undeclared key before it queries the page.
- `Filters#filter` and `Form#input` raise `Capybara::ExpectationNotMet` when the input is declared with another class.
- Typed form inputs: `Form#input` and `HasMany::Fieldset#input` return `Form::StringInput`, `SelectInput`, `BooleanInput`, `RadioInput`, `CheckBoxesInput` or `DatePickerInput` by the formtastic input class. `Form.register_type(input_class, klass)` adds one.
- `MainMenu#labels(*parents)` lists the item labels at a menu level.
- Version 1.0.0.alpha: page objects for vanilla ActiveAdmin 3 only. The gem depends on `activeadmin` (>= 3.0, < 4.0.0.a). Vanilla ActiveAdmin 4 is the 2.x line on `main`.
- SitePrism page and sections for vanilla ActiveAdmin 3: layout, breadcrumbs, action items, flashes, main menu, index table, attributes table, panel, filters (string, numeric, select, boolean, date range), scopes, pagination, batch actions and formtastic forms.
- `HasMany`, reached with `form.has_many(:orders)`: count, add and remove fieldsets, and fill their inputs.
- `StatusTag`, reached with `row.status_tag(:status)` and `attributes_table.status_tag(:status)`.
- `Sidebar`, reached with `page.sidebar("Help")`. `page.panel` skips sidebar sections and the comments panel.
- `ModalDialog`, reached with `page.modal_dialog`. `BatchActions#apply(label, inputs = {})` fills the dialog of an action with `confirm:` or `form:`.
- `Comments`, declared with `section :comments, ActiveAdminPageObjects::Comments`: read, add and delete comments.
- Table sorting: `Table#sort_by`, `#sorted_by` and `#has_sortable_column?`.
- `Tabs`, `UtilityNavigation` and `DropdownMenu` (`action_items.dropdown("More")`).
- `ActiveAdminPageObjects.register_selectors(**map)` takes only the selector map.
- `ActiveAdminPageObjects::Layout.add_section` and `Layout.add_element` add a section or an element to every page that includes `Layout`, including page classes defined earlier.
- `ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter`, `Form` and `Form::Input`. A gem with a JavaScript select widget prepends a module into it.
- `ActiveAdminPageObjects.check_version!` for theme and plugin page objects.
- `dark_mode_toggle` and `user_menu_button` raise `NotInActiveAdmin3`: ActiveAdmin 3 has neither.

### Removed

- `Table.default_header_names`. `have_header_names` and `have_no_header_names` need the names and raise `ArgumentError` without them. Declare the columns and use `have_declared_columns` instead.
