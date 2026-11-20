# Changelog

## Unreleased

### Added

- Declared labels: `AttributesTable.row(key, label = nil)`, `Table.column(key, label = nil)`, `Filters.filter(key, label = nil, type = nil)` and `Form.field(key, label = nil, type = nil)` declare a section's keys and labels, also inside a `section ... do` block. `have_declared_rows`, `have_declared_columns`, `have_declared_filters` and `have_declared_fields` compare the labels with the page exactly. `declared_label_mismatches` returns the labels that differ.
- A section with declarations raises `ArgumentError` for an undeclared key before it queries the page.
- `Filters#filter` and `Form#input` raise `Capybara::ExpectationNotMet` when the input is declared with another class.
- Typed form inputs: `Form#input` returns `Form::StringInput`, `SelectInput`, `BooleanInput`, `RadioInput`, `CheckBoxesInput` or `DatePickerInput` by the formtastic input class. `DatePickerInput` is the `date_picker` input, a native `<input type="date">`. `Form.register_type(input_class, klass)` adds one.
- `MainMenu#labels(*parents)` lists the item labels at a menu level.
- Version 2.0.0.alpha: page objects for vanilla ActiveAdmin 4 only. The gem now depends on `activeadmin` (>= 4.0.0.beta1, < 5.0.0.a). Vanilla ActiveAdmin 3 moves to the 1.x line.
- SitePrism page and sections for vanilla ActiveAdmin 4: layout, breadcrumbs, action items, flashes, main menu, index table, attributes table, panel, filters (string, numeric, select, boolean, date range), scopes, pagination, batch actions and formtastic forms.
- `ActiveAdminPageObjects.register_selectors(**map)` takes only the selector map. It can also replace a key ActiveAdmin 4 removed, such as `tabs`.
- `ActiveAdminPageObjects::Layout.add_section` and `Layout.add_element` add a section or an element to every page that includes `Layout`, including page classes defined earlier.
- `ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter`, `Form` and `Form::Input`. A gem with a JavaScript select widget prepends a module into it.
- `ActiveAdminPageObjects.check_version!` for theme and plugin page objects. Features ActiveAdmin 4 removed raise `RemovedInActiveAdmin4`.

### Removed

- `Table.default_header_names`. `have_header_names` and `have_no_header_names` need the names and raise `ArgumentError` without them. Declare the columns and use `have_declared_columns` instead.
