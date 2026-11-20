# active_admin_page_objects

A Page Object Model DSL for Capybara of ActiveAdmin, built on [SitePrism](https://github.com/site-prism/site_prism).

System specs call semantic methods, such as `table.row(id).cell(:name)`, `filters.filter(:status).select_option("Active")` or `main_menu.go("Catalog", "Orders")`, instead of CSS selectors. The selectors for vanilla ActiveAdmin 4 live in this gem.

## Versions

- 2.x supports vanilla ActiveAdmin 4 (tested on 4.0.0.beta23). This is the `main` line.
- 1.x is planned for vanilla ActiveAdmin 3, on the `1-x-stable` branch, with the same names where the component exists.

## Installation

Until the first release, install it from git:

```ruby
# Gemfile
group :test do
  gem "active_admin_page_objects", github: "senid231/active_admin_page_objects"
end
```

```ruby
# spec/rails_helper.rb, or a file in spec/support
require "active_admin_page_objects"
```

Runtime dependencies: `activeadmin` (>= 4.0.0.beta1, < 5.0.0.a), `site_prism` (>= 5.0, < 7) and `capybara` (>= 3.37).

### Rails 8 setup

```ruby
RSpec.configure do |config|
  # Rails 8 loads routes lazily. A first request to a literal URL then loads them inside the
  # Capybara server thread, which breaks the Devise session lookup.
  config.before(:suite) { Rails.application.reload_routes_unless_loaded }
end
```

## Usage

Write one page class per ActiveAdmin page and declare the sections it uses:

```ruby
class CustomerIndex < ActiveAdminPageObjects::Page
  set_url "/admin/customers{?query*}"

  section :table, ActiveAdminPageObjects::Table do
    column :id, "Id"
    column :name, "Name"
    column :email, "Email"
  end
  section :filters, ActiveAdminPageObjects::Filters
  section :scopes, ActiveAdminPageObjects::Scopes
  section :pagination, ActiveAdminPageObjects::Pagination
  section :batch_actions, ActiveAdminPageObjects::BatchActions
end

index = CustomerIndex.new
index.load
expect(index.table).to have_declared_columns
```

The `column` lines declare the header labels that `have_declared_columns` checks. A section without them takes any key and has no label check: see [Declared labels](#declared-labels).

Every `element` and `section` also gets SitePrism's `has_<name>?` and `has_no_<name>?` predicates, so `expect(index).to have_no_pagination` works.

Use the `has_no_*` matchers (`have_no_row`), not `not_to have_*`. They wait for the condition and are the only correct form with a JavaScript driver.

### Layout

`ActiveAdminPageObjects::Page` is a `SitePrism::Page` that includes `ActiveAdminPageObjects::Layout`. Include `Layout` into your own `SitePrism::Page` subclass if you already have one.

```ruby
expect(page_object).to have_site_title(text: "My Admin")
expect(page_object).to have_page_title(text: "Customers")
expect(page_object).to have_dark_mode_toggle # alias: have_theme_switcher
expect(page_object).to have_user_menu_button
expect(page_object).to have_blank_slate(text: "There are no Customers yet.")
page_object.panel("Notes").body # the panel titled "Notes"
```

### Breadcrumbs

```ruby
expect(page_object.breadcrumbs).to have_labels("Admin", "Customers")
expect(page_object.breadcrumbs).to have_no_labels("Admin")
page_object.breadcrumbs.labels # => ["Admin", "Customers"]
page_object.breadcrumbs.links # => Capybara elements
```

### Action items

```ruby
page_object.action_items.labels # => ["New Customer", "Report"]
page_object.action_items.click("New Customer")
expect(page_object.action_items).to have_item("Report")
```

`dropdown` raises `ActiveAdminPageObjects::RemovedInActiveAdmin4`: ActiveAdmin 4 has no action-item dropdown.

### Flashes

ActiveAdmin 4 renders the `notice`, `alert` and `error` types.

```ruby
expect(page_object.flashes).to have_flash(:notice, "Customer was successfully created.")
expect(page_object.flashes).to have_no_flash(:error)
page_object.flashes.messages # every flash text
page_object.flashes.messages(:alert) # one type
```

### Main menu

Items are found by their label path, case-insensitively. `go` reads the link's URL and visits it, so it works with closed submenus and under `rack_test`.

```ruby
page_object.main_menu.go("Customers")
page_object.main_menu.go("Catalog", "Orders")
expect(page_object.main_menu).to have_item("Catalog", "Categories")
page_object.main_menu.current_labels # => ["Catalog", "Orders"]
page_object.main_menu.labels("Catalog") # => ["Categories", "Orders"]
```

### Table

Cells are keyed by column: `:external_id` or `"External ID"` both match `data-column="external_id"`. `have_header_names` takes every header in order and compares case-insensitively, because ActiveAdmin 4 uppercases `th` in CSS and Chrome reports the uppercased text. To check the exact labels, declare the columns: see [Declared labels](#declared-labels).

```ruby
table = index.table
expect(table).to have_header_names("ID", "NAME", "EMAIL")
expect(table).to have_rows(count: 2)
table.header_names # as the driver reports them
table.column_keys # => ["id", "name", "email"]

row = table.row(customer.id)
row.record_id # => "42"
expect(row).to have_cell(:name, exact_text: "Acme")
expect(row).to have_no_cell(:email, text: "old@example.com")
row.cell(:email) # the <td>
row.select # ticks the batch-action checkbox
table.rows.map(&:record_id)
```

The section defaults to `table.data-table`. Pass a locator for another table, such as a `table_for` inside a panel: `section :orders, ActiveAdminPageObjects::Table, "#orders_panel table"`.

### Attributes table

Rows are keyed by the `row :foo` symbol, or by the label parameterized with `_`.

```ruby
table = show.attributes_table
expect(table).to have_row(:name, exact_text: "Acme")
expect(table).to have_no_row(:secret)
table.row(:category) # the <tr>
table.value(:email) # => "acme@example.com"
```

### Panel

```ruby
class CustomerShow < ActiveAdminPageObjects::Page
  set_url "/admin/customers/{id}"

  section :attributes_table, ActiveAdminPageObjects::AttributesTable
  section :notes, ActiveAdminPageObjects::Panel, :active_admin_panel, "Notes"
end

show.notes.title # => "Notes"
expect(show.notes.body).to have_text("Pays late")
```

### Filters

`filter(key)` returns the section typed by the filter input: `StringFilter`, `NumericFilter`, `SelectFilter`, `BooleanFilter` or `DateRangeFilter`. The key is the one given to `filter :key`; the section wraps `#q_<key>_input`.

```ruby
filters = index.filters
filters.filter(:name).fill_in(with: "Acme", predicate: "Equals") # or predicate: :eq
filters.filter(:balance).fill_in(with: 100, predicate: :gt)
filters.filter(:status).select_option("Active")
filters.filter(:active).set(true) # false, or nil for "Any"
filters.filter(:created_at).set("2026-01-01", Date.new(2026, 1, 31))
filters.submit
filters.clear

expect(filters.filter(:name)).to have_value("Acme", predicate: "Equals")
expect(filters.filter(:status)).to have_selected("Active")
expect(filters.filter(:active)).to have_value(true)
expect(filters.filter(:created_at)).to have_range("2026-01-01", "2026-01-31")
```

Declare one filter directly when a page uses it often:

```ruby
section :name_filter, ActiveAdminPageObjects::StringFilter, "#q_name_input"
section :filters_footer, ActiveAdminPageObjects::FiltersFooter # submit and clear
```

`SelectFilter` drives a native `<select>`:

```ruby
customer = filters.filter(:customer)
customer.select_option("Acme")
expect(customer).to have_option("Acme")
expect(customer).to have_selected("Acme")
expect(customer).to have_item("Acme") # the chosen item, before submit
expect(customer).to have_disabled
expect(customer).to have_no_option("Globex")
```

### Scopes

```ruby
index.scopes.labels # => ["All", "Active"]
index.scopes.select("Active")
expect(index.scopes).to have_selected("Active")
index.scopes.count("Active") # => 12, or nil without a count
```

### Pagination

ActiveAdmin renders pagination only when there is more than one page.

```ruby
index.pagination.go_to(3)
index.pagination.next_page
index.pagination.previous_page
expect(index.pagination).to have_current_page(2)
index.pagination.current_page # => 2
```

### Batch actions

Actions are found by label (`"Delete Selected"`) or by name (`:destroy`). `apply` opens the menu, clicks the action, and accepts its confirmation.

```ruby
index.table.row(customer.id).select
index.batch_actions.select_all
index.batch_actions.apply(:destroy)
expect(index.batch_actions).to have_action("Flag Selected")
```

### Form

Inputs are keyed by attribute, as in `f.input :name`.

```ruby
form = form_page.form # section :form, ActiveAdminPageObjects::Form
form.fill(:name, with: "Acme") # text, number, textarea
form.fill(:category, with: "Retail") # select, by option label
form.fill(:active, with: false) # checkbox
form.choose(:status, "pending") # select or radio
form.submit

expect(form).to have_input_error(:email, "is invalid")
expect(form).to have_semantic_errors("Name is reserved")
form.input(:email).errors # => ["is invalid"]
```

`input(key)` returns the section typed by the formtastic input class. Every one has `fill`, `choose` and `errors`.

- `Form::StringInput` for `string`, `email`, `url`, `phone`, `password`, `number` and `text`: `value`.
- `Form::SelectInput` for `select`: `options` (without the blank option) and `selected`.
- `Form::BooleanInput` for `boolean`: `checked?`.
- `Form::RadioInput` for `radio`: `options` and `selected`.
- `Form::CheckBoxesInput` for `check_boxes`: `check(*labels)`, `uncheck(*labels)` and `checked`.
- `Form::DatePickerInput` for `date_picker`, a native `<input type="date">`: `fill` takes a Date or a string such as `"2026-01-31"`.
- `Form::Input` for any other class.

```ruby
form.input(:status).options # => ["active", "pending", "closed"]
form.input(:status).selected # => "pending", or nil for the blank option
expect(form.input(:active)).to be_checked
form.input(:tier).selected # => "Gold", the chosen radio button
form.input(:channels).check("Email", "Post")
form.input(:channels).checked # => ["Email", "Post"]
form.fill(:signed_on, with: Date.new(2026, 1, 31))
```

### Tabs

ActiveAdmin 4 removed the `tabs` component. `ActiveAdminPageObjects::Tabs` raises `RemovedInActiveAdmin4`. A theme that brings tabs back registers a `tabs` selector and patches the section.

## Declared labels

Sections find elements by key, so `row(:external_id)` passes whatever its label says. Declare each key with its label on the section, then check every label with one matcher.

```ruby
class CustomerIndex < ActiveAdminPageObjects::Page
  set_url "/admin/customers{?query*}"

  section :table, ActiveAdminPageObjects::Table do
    column :id, "Id"
    column :external_id, "External ID"
  end
  section :filters, ActiveAdminPageObjects::Filters do
    filter :external_id, "External ID"
    filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
  end
end

class CustomerShow < ActiveAdminPageObjects::Page
  set_url "/admin/customers/{id}"

  section :attributes_table, ActiveAdminPageObjects::AttributesTable do
    row :name, "Name"
    row :external_id, "External ID"
  end
end

class CustomerForm < ActiveAdminPageObjects::Page
  set_url "/admin/customers{/id}{/action}"

  section :form, ActiveAdminPageObjects::Form do
    field :name, "Name"
    field :status, "Status", ActiveAdminPageObjects::Form::SelectInput
  end
end

expect(index.table).to have_declared_columns
expect(index.filters).to have_declared_filters
expect(show.attributes_table).to have_declared_rows
expect(form_page.form).to have_declared_fields
```

SitePrism 5 and 6 turn the block into a subclass of the section class. A named subclass takes the same lines in its class body. A subclass inherits the declarations of its superclass and adds its own.

### Label matchers

`have_declared_columns`, `have_declared_filters`, `have_declared_rows` and `have_declared_fields` compare each declared label with the text in the DOM. The comparison is exact and case-sensitive, so `"External id"` does not match `"External ID"`. Only whitespace is normalized.

- CSS `text-transform` does not change the result, on any driver. ActiveAdmin 4 uppercases the `th` of both tables in CSS; declare the label as the DOM has it, such as `"External ID"`.
- In filter and form labels, the text of links, buttons and `abbr` elements is not part of the label. That drops the required marker (`*`) and controls that plugins append, such as the date range preset's "Set range" link.
- The order is not checked. Elements that are on the page but not declared are ignored.
- They wait like the other matchers. `have_no_declared_columns` and the other three wait until a label differs.
- They raise `ArgumentError` on a section that declares nothing.

When a matcher fails, `declared_label_mismatches` returns each failing key with the label found, or `nil` when the page has no such element:

```ruby
index.table.declared_label_mismatches # => { "external_id" => "External Id", "secret" => nil }
```

### Strict keys

A section that declares anything raises `ArgumentError` for every other key, before it queries the page. The message names the key and lists the declared keys. A section without declarations takes any key, as before.

- `AttributesTable`: `has_row?`, `has_no_row?`, `row` and `value`.
- `Table`: its rows' `cell`, `has_cell?` and `has_no_cell?`.
- `Filters`: `filter`.
- `Form`: `input`, `fill`, `choose`, `has_input_error?` and `has_no_input_error?`.

A key declared without a label is known but not compared: `row :notes` lets `have_no_row(:notes)` check that the row is absent, and `column :actions` covers the untitled actions column.

Keys compare as everywhere else: `:external_id`, `"external_id"` and `"External ID"` are the same key.

### Declared types

`filter` and `field` take a section class as the third argument. `filters.filter(key)` and `form.input(key)`, and so `form.fill` and `form.choose`, then raise `Capybara::ExpectationNotMet` unless the page has an input of that class or a subclass. The message names both classes.

## JavaScript driver

These need a JavaScript driver such as Cuprite or Selenium:

- `BatchActions#apply`: ActiveAdmin's JavaScript opens the menu and submits the form.
- `StringFilter#fill_in` and `NumericFilter#fill_in` with a predicate other than the selected one: the JavaScript renames the input when the predicate changes.

Everything else works with `rack_test` too, including `MainMenu#go`, filters with the current predicate, plain selects, date ranges, scopes, pagination and forms.

## Selectors

Sections resolve their selectors when Capybara runs the query, through the `:active_admin` Capybara selector: `find(:active_admin, :table)`. Requiring the gem before ActiveAdmin loads is safe.

## Extending sections

Subclass a section, or include a module into one:

```ruby
module TruncatedCells
  def truncated_text(key)
    cell(key).find(".truncate-text").text
  end
end
ActiveAdminPageObjects::Table::Row.include(TruncatedCells)

class StatusPanel < ActiveAdminPageObjects::Panel
  def status = body.find(".status").text
end
```

Base your own sections on `ActiveAdminPageObjects::Section` to get `selector_key`, which points the default locator at a selector-map entry, and to share the map with the gem:

```ruby
ActiveAdminPageObjects.register_selectors(audit_panel: "[data-audit-panel]")

class AuditPanel < ActiveAdminPageObjects::Section
  selector_key :audit_panel
end
```

`register_selectors` can also replace a key that ActiveAdmin 4 removed, such as `tabs`.

Add a section or an element to every page that includes `Layout`, including page classes defined earlier:

```ruby
ActiveAdminPageObjects::Layout.add_section(:audit_panel, AuditPanel)
ActiveAdminPageObjects::Layout.add_element(:banner, ".banner")
```

Register a section for a custom filter input class with `ActiveAdminPageObjects::Filters.register_type("my_input", MyFilter)`, and for a custom form input class with `ActiveAdminPageObjects::Form.register_type("my_input", MyInput)`. `MyInput` subclasses `ActiveAdminPageObjects::Form::Input`.

### Select widgets

`ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter`, `Form` and `Form::Input`. A gem with a JavaScript select widget prepends a module into it and overrides the private methods `choose_option(scope, label)`, `option_offered?(scope, label)`, `control_disabled?(scope)` and `chosen_item?(scope, label)`:

```ruby
module MyWidget
  module SelectControl
    private

    def choose_option(scope, label)
      # open the widget and click the option
    end
  end
end
ActiveAdminPageObjects::SelectControl.prepend(MyWidget::SelectControl)
```

## Themes and plugins

A theme or plugin ships its own page objects in its own repository, with one entry point. The rule:

- A new component gets a new section in that gem.
- A change to a vanilla component ships as a patch to the base section: a selector override with `register_selectors`, or a module prepended to the base class.

```ruby
# lib/my_plugin/page_objects.rb
require "active_admin_page_objects"
ActiveAdminPageObjects.check_version!(">= 2.0.0.a", "< 3", plugin: "my_plugin")

module MyPlugin
  class Widget < ActiveAdminPageObjects::Section
    # ...
  end
end

ActiveAdminPageObjects::Layout.add_section(:widget, MyPlugin::Widget)
```

Apps load it with `require "my_plugin/page_objects"`.

## Development

```sh
bundle install
bundle exec rake # builds the dummy app's CSS (npm), runs rubocop and rspec
BUNDLE_GEMFILE=gemfiles/site_prism_5.gemfile bundle exec rspec
```

The specs drive a Rails 8 dummy app with ActiveAdmin 4 (`spec/dummy`) through headless Chrome with Cuprite.

## License

MIT
