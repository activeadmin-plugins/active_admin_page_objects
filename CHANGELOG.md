# Changelog

## Unreleased

### Added

- Declared elements: `AttributesTable.row(key, label)`, `Table.column(key, label)`, `Filters.filter(name, label, type)` and `Form.field(name, label, type)` declare a section's elements with their labels, also inside a `section ... do` block. A filter or a field also needs its section class.
- `have_declared_rows`, `have_declared_columns`, `have_declared_filters` and `have_declared_fields` compare the declared labels with the page exactly. `have_exact_rows`, `have_exact_columns`, `have_exact_filters` and `have_exact_fields` also fail when the page has an element that is not declared. All take `only:` and `except:`. `declared_label_mismatches` and `exact_mismatches` return what differs.
- The untitled selection and actions columns of an index table are the columns `selectable` and `actions`, declared with the label `""`. ActiveAdmin 4 gives them no `data-column`.
- `Filters#filter` and `Form#field` return an instance of the declared class, and raise `Capybara::ExpectationNotMet` unless it is the detected class or a subclass of it. A declaration defines no method on the section: reach it with `form.field(:name)` or `filters.filter(:name)`, and write your own methods in the section block for shortcuts.
- A section with declarations raises `ArgumentError` for an undeclared name before it queries the page.
- Typed form fields: `Form#field` returns `Form::StringField`, `SelectField`, `BooleanField`, `RadioField`, `CheckBoxesField` or `DatePickerField` by the formtastic input class. Each has a `fill(value)` for its type. `DatePickerField` is the `date_picker` input, a native `<input type="date">`. `form.fill(name: "Acme", active: false)` fills several fields in the given order. `Form.register_type(input_class, klass)` adds a class.
- Form errors: `have_field_error`, `have_field_errors`, `have_exact_field_errors`, `have_semantic_errors` and `have_exact_semantic_errors(*messages, strict_order: false)`, each with its `have_no_` form.
- `Panel#links` lists the links of the body as `{ text:, href: }`, with the `href` attribute as the page wrote it.
- `ActiveAdminPageObjects::RSpec::Matchers`, loaded with `require "active_admin_page_objects/rspec"`: the matcher names of capybara_active_admin 1.0.0, which call the predicate of a page object and that gem's matcher for anything else.
- `MainMenu#labels(*parents)` lists the item labels at a menu level.
- Version 2.0.0.alpha: page objects for vanilla ActiveAdmin 4 only. The gem now depends on `activeadmin` (>= 4.0.0.beta1, < 5.0.0.a). Vanilla ActiveAdmin 3 moves to the 1.x line.
- SitePrism page and sections for vanilla ActiveAdmin 4: layout, breadcrumbs, action items, flashes, main menu, index table, attributes table, panel, filters (string, numeric, select, boolean, date range), scopes, pagination, batch actions and formtastic forms.
- `ActiveAdminPageObjects.register_selectors(**map)` takes only the selector map. It can also replace a key ActiveAdmin 4 removed, such as `tabs`.
- `ActiveAdminPageObjects::Layout.add_section` and `Layout.add_element` add a section or an element to every page that includes `Layout`, including page classes defined earlier.
- `ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter` and `Form::Field`. A gem with a JavaScript select widget prepends a module into it.
- `ActiveAdminPageObjects.check_version!` for theme and plugin page objects. Features ActiveAdmin 4 removed raise `RemovedInActiveAdmin4`.

### Removed

- `Table.default_header_names`. `have_header_names` and `have_no_header_names` need the names and raise `ArgumentError` without them. Declare the columns and use `have_declared_columns` instead.
