# Changelog

## Unreleased

### Added

- Declared elements: `AttributesTable.row(key, label)`, `Table.column(key, label)`, `Filters.filter(name, label, type)` and `Form.field(name, label, type)` declare a section's elements with their labels, also inside a `section ... do` block. A filter or a field also needs its section class.
- `have_declared_rows`, `have_declared_columns`, `have_declared_filters` and `have_declared_fields` compare the declared labels with the page exactly. `have_exact_rows`, `have_exact_columns`, `have_exact_filters` and `have_exact_fields` also fail when the page has an element that is not declared. All take `only:` and `except:`. `declared_label_mismatches` and `exact_mismatches` return what differs.
- `Filters#filter` and `Form#field` return an instance of the declared class, and raise `Capybara::ExpectationNotMet` unless it is the detected class or a subclass of it. A declaration defines no method on the section: reach it with `form.field(:name)` or `filters.filter(:name)`, and write your own methods in the section block for shortcuts.
- `Form.has_many(name, heading, &block)` declares a has_many block with the fields of its fieldsets, reached with `form.has_many(:name)`.
- A section with declarations raises `ArgumentError` for an undeclared name before it queries the page.
- Typed form fields: `Form#field` and `HasMany::Fieldset#field` return `Form::StringField`, `SelectField`, `BooleanField`, `RadioField`, `CheckBoxesField` or `DatePickerField` by the formtastic input class. Each has a `fill(value)` for its type. `form.fill(name: "Acme", active: false)` fills several fields in the given order, on a form and on a has_many fieldset. `Form.register_type(input_class, klass)` adds a class.
- Form errors: `have_field_error`, `have_field_errors`, `have_exact_field_errors`, `have_semantic_errors` and `have_exact_semantic_errors(*messages, strict_order: false)`, each with its `have_no_` form. Has_many fieldsets have the field error matchers too.
- `have_status_tag(key, label, type: nil)` and `have_no_status_tag` on index rows and on the attributes table.
- `Panel#links` and `Sidebar#links` list the links of the body as `{ text:, href: }`, with the href as a path.
- `ActiveAdminPageObjects::RSpec::Matchers`, loaded with `require "active_admin_page_objects/rspec"`: the matcher names of capybara_active_admin 1.0.0, which call the predicate of a page object and that gem's matcher for anything else.
- `MainMenu#labels(*parents)` lists the item labels at a menu level.
- Version 1.0.0.alpha: page objects for vanilla ActiveAdmin 3 only. The gem depends on `activeadmin` (>= 3.0, < 4.0.0.a). Vanilla ActiveAdmin 4 is the 2.x line on `main`.
- SitePrism page and sections for vanilla ActiveAdmin 3: layout, breadcrumbs, action items, flashes, main menu, index table, attributes table, panel, filters (string, numeric, select, boolean, date range), scopes, pagination, batch actions and formtastic forms.
- `HasMany`, reached with `form.has_many(:orders)`: count, add and remove fieldsets, and fill their fields.
- `StatusTag`, reached with `row.status_tag(:status)` and `attributes_table.status_tag(:status)`.
- `Sidebar`, reached with `page.sidebar("Help")`. `page.panel` skips sidebar sections and the comments panel.
- `ModalDialog`, reached with `page.modal_dialog`. `BatchActions#apply(label, inputs = {})` fills the dialog of an action with `confirm:` or `form:`.
- `Comments`, declared with `section :comments, ActiveAdminPageObjects::Comments`: read, add and delete comments.
- Table sorting: `Table#sort_by`, `#sorted_by` and `#has_sortable_column?`.
- `Tabs`, `UtilityNavigation` and `DropdownMenu` (`action_items.dropdown("More")`).
- `ActiveAdminPageObjects.register_selectors(**map)` takes only the selector map.
- `ActiveAdminPageObjects::Layout.add_section` and `Layout.add_element` add a section or an element to every page that includes `Layout`, including page classes defined earlier.
- `ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter` and `Form::Field`. A gem with a JavaScript select widget prepends a module into it.
- `ActiveAdminPageObjects.check_version!` for theme and plugin page objects.
- `dark_mode_toggle` and `user_menu_button` raise `NotInActiveAdmin3`: ActiveAdmin 3 has neither.

### Removed

- `Table.default_header_names`. `have_header_names` and `have_no_header_names` need the names and raise `ArgumentError` without them. Declare the columns and use `have_declared_columns` instead.
