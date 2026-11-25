# Changelog

## Unreleased

### Added

- `ActiveAdminPageObjects.register_field_class(wrapper_class, field_class)` and `.register_filter_class(wrapper_class, filter_class)`: a theme or plugin maps the formtastic class of its own input to its section class, and `form.field` and `filters.filter` return that class without a declaration. A registered class wins over the gem's class.

## 1.0.0 (2026-11-24)

### Added

- Arguments that would make a matcher pass on any page raise `ArgumentError`: a record id that is not an Integer or a non-empty String in `Table#row`, `#has_row?` and `#has_no_row?`, an `only:` or `except:` scope that leaves no declared name, and a flash type of `nil`.
- `MainMenu#has_item?` and `#has_no_item?` wait, and take `wait:`.
- `DateRangeFilter#set` clears an end for `""` as for `nil`.
- `have_table` from `ActiveAdminPageObjects::RSpec::Matchers` calls the page object only when it defines `has_table?` itself, as `section :table` does; Capybara's own `has_table?` does not count.
- `Form::FileField` for formtastic's `file` input: `fill(path)` attaches the file, and `form.fill(attachment: path)` works. `Form#field` and `HasMany::Fieldset#field` return it by the input class.
- Disabled fields: `Form::Field#disabled?` and `#enabled?` on every field type, and `have_disabled_field(name)` and `have_enabled_field(name)` with their `have_no_` forms on a form and on a has_many fieldset.
- `have_status_tag` and `have_no_status_tag` look at every status tag of the cell, not only the first. `status_tags(key)` on an index row and on the attributes table returns all of them.
- `Table#has_row?(record_id)` and `#has_no_row?(record_id)`: `expect(table).to have_row(customer.id)`.
- Regexp titles: `Tabs#switch`, `have_tab`, `page.panel`, `page.sidebar` and the `:active_admin_panel` and `:active_admin_sidebar` selectors take a Regexp for a title with a changing part, such as "Possible Routes (2)". A String still compares the whole title.
- `DownloadLinks`, declared with `section :download_links, ActiveAdminPageObjects::DownloadLinks`: `formats`, `have_format(format)`, `href(format)` and `click(format)` for the "Download: CSV XML JSON" links of an index page.
- Declared elements: `AttributesTable.row(key, label)`, `Table.column(key, label)`, `Filters.filter(name, label, type)` and `Form.field(name, label, type)` declare a section's elements with their labels, also inside a `section ... do` block. A filter or a field also needs its section class.
- `have_declared_rows`, `have_declared_columns`, `have_declared_filters` and `have_declared_fields` compare the declared labels with the page exactly. `have_exact_rows`, `have_exact_columns`, `have_exact_filters` and `have_exact_fields` also fail when the page has an element that is not declared. All take `only:` and `except:`. `declared_label_mismatches` and `exact_mismatches` return what differs.
- Lookups and matchers see only visible elements, as Capybara does by default. `visible: :all` on a call takes hidden elements too: `form.field(:notes, visible: :all)`, `have_exact_fields(visible: :all)`, `exact_mismatches(visible: :all)`. `visible: :all` on a declaration makes it the default for that element: `field :notes, "Notes", ActiveAdminPageObjects::Form::StringField, visible: :all`.
- Failure messages: with `ActiveAdminPageObjects::RSpec::Matchers` included, the `have_declared_*` and `have_exact_*` matchers and their `have_no_` forms list the missing elements, the unexpected elements and the labels that differ. `have_exact_field_errors` and `have_exact_semantic_errors` list the missing and the unexpected messages. `last_mismatches`, `last_field_errors` and `last_semantic_errors` return what the last of these matchers found.
- `Filters#filter` and `Form#field` return an instance of the declared class, and raise `ActiveAdminPageObjects::DeclaredClassMismatch`, a `Capybara::ExpectationNotMet`, unless it is the detected class or a subclass of it. `have_disabled_field` and `have_enabled_field` raise it too. To use your own field or filter class, declare it. A declaration defines no method on the section: reach it with `form.field(:name)` or `filters.filter(:name)`, and write your own methods in the section block for shortcuts.
- `Form.has_many(name, heading, &block)` declares a has_many block with the fields of its fieldsets, reached with `form.has_many(:name)`.
- A section with declarations raises `ArgumentError` for an undeclared name before it queries the page.
- Typed form fields: `Form#field` and `HasMany::Fieldset#field` return `Form::StringField`, `SelectField`, `BooleanField`, `RadioField`, `CheckBoxesField` or `DatePickerField` by the formtastic input class. Each has a `fill(value)` for its type. `form.fill(name: "Acme", active: false)` fills several fields in the given order, on a form and on a has_many fieldset.
- Form errors: `have_field_error`, `have_field_errors`, `have_exact_field_errors`, `have_semantic_errors` and `have_exact_semantic_errors(*messages, strict_order: false)`, each with its `have_no_` form. Has_many fieldsets have the field error matchers too.
- `have_status_tag(key, label, type: nil)` and `have_no_status_tag` on index rows and on the attributes table.
- `Panel#links` and `Sidebar#links` list the links of the body as `{ text:, href: }`, with the href as a path.
- `ActiveAdminPageObjects::RSpec::Matchers`, loaded with `require "active_admin_page_objects/rspec"`: the matcher names of capybara_active_admin 1.0.0, which call the predicate of a page object and that gem's matcher for anything else.
- `MainMenu#labels(*parents)` lists the item labels at a menu level. `MainMenu#click(*labels)` hovers each parent and clicks the item's link, as a user does; it sees visible items only, so a hidden submenu raises `Capybara::ElementNotFound`. `go` still visits the link's URL.
- Version 1.0.0: page objects for vanilla ActiveAdmin 3 only. The gem depends on `activeadmin` (>= 3.0, < 4.0.0.a). Vanilla ActiveAdmin 4 is the 2.x line on `main`.
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
- `ActiveAdminPageObjects::SelectControl` drives a visible native `<select>` for `SelectFilter`, `BooleanFilter`, `Form::SelectField`, `Form::Field` and the predicate select of `StringFilter` and `NumericFilter`. A `<select>` that is hidden or marked `aria-hidden="true"`, as a JavaScript select widget leaves it, raises `Capybara::ElementNotFound` when it is picked from or read. A section class for a widget overrides the private `native_select_visibility` to return `:all` and read the hidden select, and overrides `select_option` or `fill` to drive the widget. A gem with a widget on every select prepends a module into `SelectControl`.
- `ActiveAdminPageObjects.check_version!` for theme and plugin page objects.
- `dark_mode_toggle` and `user_menu_button` raise `NotInActiveAdmin3`: ActiveAdmin 3 has neither.

### Removed

- `Table.default_header_names`. `have_header_names` and `have_no_header_names` need the names and raise `ArgumentError` without them. Declare the columns and use `have_declared_columns` instead.
