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

Runtime dependencies: `activeadmin` (>= 4.0.0.beta1, < 5.0.0.a), `site_prism` (>= 5.0, < 7) and `capybara` (>= 3.37), on Ruby 3.3 or later.

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

The `column` lines declare the columns and the header labels that `have_declared_columns` checks. A section without them takes any key and has no label check: see [Declared labels](#declared-labels).

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

Items are found by their label path, case-insensitively. `go` reads the link's URL and visits it, so it works with closed submenus and under `rack_test`. `click` drives the menu as a user does: it opens each collapsed parent with its toggle button, then clicks the item's link. It sees visible items only, so a submenu that stays hidden raises `Capybara::ElementNotFound`. Under `rack_test`, which has no JavaScript, the submenus are never collapsed, so `click` just clicks the link.

```ruby
page_object.main_menu.go("Customers")
page_object.main_menu.go("Catalog", "Orders")
page_object.main_menu.click("Catalog", "Orders")
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
expect(table).to have_row(customer.id) # by record id
expect(table).to have_no_row(deleted.id)
```

`row`, `have_row` and `have_no_row` take the record id: an Integer or a non-empty String. Anything else, such as the record itself or `nil`, raises `ArgumentError`.

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
show.notes.links # => [{ text: "Invoices", href: "/admin/invoices?customer=1" }]
```

`links` lists the links of the body, each with its text and its `href` attribute as the page wrote it, on every driver.

A String title is the whole title, ignoring case. For a title with a changing part, such as "Possible Routes (2)", pass a Regexp, which is case-sensitive unless it has `/i`. It works for `page.panel` and the `:active_admin_panel` selector:

```ruby
section :routes, ActiveAdminPageObjects::Panel, :active_admin_panel, /\APossible Routes \(\d+\)\z/

show.panel(/\APossible Routes/).title # => "Possible Routes (2)"
```

### Filters

`filter(key)` returns the section typed by the filter input: `StringFilter`, `NumericFilter`, `SelectFilter`, `BooleanFilter` or `DateRangeFilter`. The key is the one given to `filter :key`; the section wraps `#q_<key>_input`. Filters that [declare their filters](#declared-labels) take the declared name.

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

`DateRangeFilter#set` takes Date objects or ISO strings; `nil` or `""` clears that end.

Declare one filter directly when a page uses it often:

```ruby
section :name_filter, ActiveAdminPageObjects::StringFilter, "#q_name_input"
section :filters_footer, ActiveAdminPageObjects::FiltersFooter # submit and clear
```

`SelectFilter` drives a visible native `<select>`. One that is hidden or marked `aria-hidden="true"`, as a JavaScript select widget leaves it, raises `Capybara::ElementNotFound`: see [Hidden selects](#hidden-selects).

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

### Download links

The "Download: CSV XML JSON" links under the index table. ActiveAdmin renders them only when the index has records. A format is named by its link text, ignoring case.

```ruby
links = index.download_links # section :download_links, ActiveAdminPageObjects::DownloadLinks
links.formats # => ["CSV", "XML", "JSON"]
expect(links).to have_format("CSV")
expect(links).to have_no_format("PDF")
links.href(:csv) # => "/admin/customers.csv", the attribute as written
links.click(:csv)
```

Under `rack_test`, `click` loads the file: read it from `page.body`. A JavaScript driver downloads a CSV file as the browser does and stays on the page.

### Batch actions

Actions are found by label (`"Delete Selected"`) or by name (`:destroy`). `apply` opens the menu, clicks the action, and accepts its confirmation.

```ruby
index.table.row(customer.id).select
index.batch_actions.select_all
index.batch_actions.apply(:destroy)
expect(index.batch_actions).to have_action("Flag Selected")
```

### Form

Fields are named by attribute, as in `f.input :email`. A form that [declares its fields](#declared-labels) takes the declared names.

```ruby
form = form_page.form # section :form, ActiveAdminPageObjects::Form
form.field(:email).fill("acme@example.com")
form.fill(name: "Acme", category: "Retail", active: false) # in this order
form.submit
```

`field(name)` returns the section typed by the formtastic input class. `fill(value)` sets the field the way its type needs.

- `Form::StringField` for `string`, `email`, `url`, `phone`, `password`, `number` and `text`: `fill` types the value. `value`.
- `Form::SelectField` for `select`: `fill` picks the option with that label. `options` (without the blank option) and `selected`. The `<select>` is visible: see [Hidden selects](#hidden-selects).
- `Form::BooleanField` for `boolean`: `fill(true)` ticks the checkbox and `fill(false)` unticks it. `checked?`.
- `Form::RadioField` for `radio`: `fill` picks the radio button with that label. `options` and `selected`.
- `Form::CheckBoxesField` for `check_boxes`: `fill` takes an array of labels, ticks them and unticks the others. `check(*labels)`, `uncheck(*labels)` and `checked`.
- `Form::DatePickerField` for `date_picker`, a native `<input type="date">`: `fill` takes a Date or a string such as `"2026-01-31"`.
- `Form::FileField` for `file`: `fill` takes the path of the file and attaches it. A JavaScript driver needs an absolute path.
- `Form::Field` for any other class: `fill` types text, picks a select option or ticks a checkbox, by what the wrapper holds.

Every field also has `errors`, `disabled?` and `enabled?`, and `choose(option)` for a select or a radio button.

```ruby
form.field(:status).options # => ["active", "pending", "closed"]
form.field(:status).selected # => "pending", or nil for the blank option
expect(form.field(:active)).to be_checked
form.field(:tier).selected # => "Gold", the chosen radio button
form.field(:channels).fill(%w[Email Post])
form.field(:channels).checked # => ["Email", "Post"]
form.field(:signed_on).fill(Date.new(2026, 1, 31))
form.field(:contract).fill(Rails.root.join("spec/fixtures/contract.pdf"))
```

#### Disabled fields

```ruby
expect(form).to have_disabled_field(:code)
expect(form).to have_enabled_field(:name)
expect(form).to have_no_disabled_field(:name)
form.field(:code).disabled? # => true, without waiting
```

- A field is disabled when every control in it is: the input, the select, or each radio button or checkbox of a field with choices. It is enabled when a control is not disabled. Hidden inputs do not count.
- `have_no_disabled_field` and `have_no_enabled_field` also pass when the form has no such field.
- The matchers wait, and take `visible:` like `field`.

#### Form errors

```ruby
expect(form).to have_field_error(:email, "is invalid") # the inline error contains the text
expect(form).to have_no_field_error(:name)
expect(form).to have_field_errors # any inline error
expect(form).to have_no_field_errors
expect(form).to have_exact_field_errors(name: "can't be blank", email: ["is invalid"])
form.field(:email).errors # => ["is invalid"]

expect(form).to have_semantic_errors("Name is reserved") # every message is shown; ignores case
expect(form).to have_exact_semantic_errors("Name is reserved", "Balance is negative")
expect(form).to have_exact_semantic_errors("Name is reserved", "Balance is negative", strict_order: true)
form.semantic_errors # => ["Name is reserved", "Balance is negative"]
```

- `have_field_errors` and `have_no_field_errors` look at the whole form.
- `have_exact_field_errors` takes each field with its message, or an array of messages. Every one of these fields shows exactly these messages, and no other field shows an error. Without arguments it passes when no field shows an error. Its keywords are field names, so it takes no Capybara options and no `visible:`. See [Hidden elements](#hidden-elements).
- `have_exact_semantic_errors` compares the base errors exactly and case-sensitively: the same messages, in any order. `strict_order: true` compares the order too. Without messages it passes when the form shows no base error.
- `have_no_exact_field_errors` and `have_no_exact_semantic_errors` wait until the errors differ.

### Tabs

ActiveAdmin 4 removed the `tabs` component. `ActiveAdminPageObjects::Tabs` raises `RemovedInActiveAdmin4`. A theme that brings tabs back registers a `tabs` selector and patches the section.

## Declared labels

Sections find elements by key, so `row(:external_id)` passes whatever its label says. Declare each element with its label on the section, then check all of them with one matcher.

```ruby
class CustomerIndex < ActiveAdminPageObjects::Page
  set_url "/admin/customers{?query*}"

  section :table, ActiveAdminPageObjects::Table do
    column :selectable, ""
    column :id, "Id"
    column :external_id, "External ID"
    column :actions, ""
  end
  section :filters, ActiveAdminPageObjects::Filters do
    filter :external_id, "External ID", ActiveAdminPageObjects::StringFilter
    filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
  end
end

class CustomerShow < ActiveAdminPageObjects::Page
  set_url "/admin/customers/{id}"

  section :attributes_table, ActiveAdminPageObjects::AttributesTable do
    row :email, "Email"
    row :external_id, "External ID"
  end
end

class CustomerForm < ActiveAdminPageObjects::Page
  set_url "/admin/customers{/id}{/action}"

  section :form, ActiveAdminPageObjects::Form do
    field :email, "Email", ActiveAdminPageObjects::Form::StringField
    field :status, "Status", ActiveAdminPageObjects::Form::SelectField
  end
end

expect(index.table).to have_exact_columns
expect(index.filters).to have_exact_filters
expect(show.attributes_table).to have_exact_rows
expect(form_page.form).to have_exact_fields
```

- `row(key, label)` and `column(key, label)` need the label. An untitled column takes `""`: the selection column is `:selectable` and the actions column is `:actions`.
- `filter(name, label, type)` and `field(name, label, type)` need the label and the section class.
- Each takes `visible:` for an element that may be hidden: see [Hidden elements](#hidden-elements).

SitePrism 5 and 6 turn the block into a subclass of the section class. A named subclass takes the same lines in its class body. A subclass inherits the declarations of its superclass and adds its own.

### Declarations define no methods

A declaration defines no method on the section, so any name is valid, including `name` and `title`. Reach an element with `filter(name)` or `field(name)`:

```ruby
index.filters.filter(:balance).fill_in(with: 100, predicate: :gt)
form_page.form.field(:status).fill("pending")
```

The name is the formtastic attribute or the ActiveAdmin filter key, and the only key: `field :name, "Name", ActiveAdminPageObjects::Form::StringField` is reached with `field(:name)`, `has_field_error?(:name)` and `fill(name: ...)`. A subclass can declare an inherited name again.

For shortcuts, write your own methods in the section block.

### Declared types

`filters.filter(name)` and `form.field(name)` return an instance of the declared class. To use your own field or filter class, declare it. It is a subclass of the gem's class for that input:

```ruby
class MySelectField < ActiveAdminPageObjects::Form::SelectField
  # drives the widget: see Hidden selects below
end

section :form, ActiveAdminPageObjects::Form do
  field :status, "Status", MySelectField
end
```

The declared class must be the class the gem detects for the wrapper, or a subclass of it. Otherwise the lookup raises `ActiveAdminPageObjects::DeclaredClassMismatch`, a `Capybara::ExpectationNotMet`, and the message names both classes. `have_disabled_field` and `have_enabled_field` raise it too.

Two of the gem's classes are subclasses of another detected class, so the check takes them for the parent's input: `Form::DatePickerField` on a string input, and `BooleanFilter` on a select filter.

The gem detects its own classes by the formtastic class of the wrapper, and `Form::Field` or `Filter` for any other input. That list is fixed: there is no registry to add to. A section without declarations returns the detected class.

### Hidden selects

`SelectFilter`, `BooleanFilter`, `Form::SelectField`, `Form::Field` and the predicate select of `StringFilter` and `NumericFilter` find the native `<select>` as Capybara finds elements by default, and leave out a select marked `aria-hidden="true"`. When it is hidden or marked so, as a JavaScript select widget leaves it, picking and reading raise `Capybara::ElementNotFound`: `select_option`, `fill`, `selected`, `options`, `have_selected`, `have_option`, `have_item`, `have_disabled` and their `have_no_` forms. A page object that declares `SelectFilter` on a widget fails, and does not drive the select behind the widget.

For a widget, declare your own class. Override the method that picks, to drive the widget, and the private `native_select_visibility`, to read the select the widget hides:

```ruby
class MySelectFilter < ActiveAdminPageObjects::SelectFilter
  def select_option(label)
    find(".my-widget-toggle").click
    # the widget may append its dropdown to <body>, outside the filter
    root_element.session.find(".my-widget-option", exact_text: label).click
  end

  private

  def native_select_visibility
    :all
  end
end

section :filters, ActiveAdminPageObjects::Filters do
  filter :customer, "Customer", MySelectFilter
end

filters.filter(:customer).select_option("Acme") # clicks the widget
expect(filters.filter(:customer)).to have_selected("Acme") # reads the hidden <select>
```

- `native_select_visibility` returns the Capybara `visible:` value of every lookup of the native `<select>`: `:all`, `:hidden`, `:visible`, `true` or `false`. The default is `nil`: no `visible:`, so `Capybara.ignore_hidden_elements` decides.
- A lookup of visible elements also leaves out a select marked `aria-hidden="true"`, on every driver. A widget may clip its select to one pixel, which Cuprite reports as visible, and mark it `aria-hidden`. `:all` takes that select too.
- With `:all` the inherited methods pick from the hidden select and read it. Override the ones that have to go through the widget.
- A `Form::SelectField` subclass overrides `fill` the same way.

### Label matchers

`have_declared_columns`, `have_declared_filters`, `have_declared_rows` and `have_declared_fields` pass when every declared element is on the page with exactly its label. The comparison is exact and case-sensitive, so `"External id"` does not match `"External ID"`. Only whitespace is normalized.

- CSS `text-transform` does not change the result, on any driver. ActiveAdmin 4 uppercases the `th` of both tables in CSS; declare the label as the DOM has it, such as `"External ID"`.
- In filter and form labels, the text of links, buttons and `abbr` elements is not part of the label. That drops the required marker (`*`) and controls that plugins append, such as the date range preset's "Set range" link.
- The order is not checked. Elements that are on the page but not declared are ignored: the exact matchers catch those.
- They wait like the other matchers. `have_no_declared_columns` and the other three wait until a label differs.
- They raise `ArgumentError` on a section that declares nothing.

### Exact matchers

`have_exact_columns`, `have_exact_filters`, `have_exact_rows` and `have_exact_fields` pass when the label matcher passes and the page has no other element of that kind:

- Rows: the `tr[data-row]` of the attributes table.
- Columns: the `th[data-column]` of the table, and the untitled selection and actions columns.
- Filters: the filter wrappers of the filter form.
- Form fields: the input wrappers of the form. `as: :hidden` inputs are not fields.

ActiveAdmin 4 writes no `data-column` on an untitled column. The selection column is the one whose header holds the toggle-all checkbox, and the actions column is the one whose cells hold the row actions. Any other untitled column has no key, so the matchers leave it out.

Only visible elements count: see [Hidden elements](#hidden-elements).

`have_no_exact_columns` and the other three wait until the page differs.

### only and except

The label matchers and the exact matchers take `only:` and `except:`: a declared name, or an array of them. A name that is not declared raises `ArgumentError`.

```ruby
expect(index.table).to have_exact_columns(except: :notes) # a column that only some users see
expect(form_page.form).to have_declared_fields(only: %i[email status])
```

- `only:` checks these elements and ignores the rest of the page, so no element is unexpected.
- `except:` skips these elements: the page may have them or not.
- A scope that leaves no declared name, such as `only: []`, raises `ArgumentError`: it would pass on any page.

### Hidden elements

Lookups and matchers see only visible elements, as Capybara does by default. A hidden field, filter, row or column is not found. The label matchers report it as missing, and the exact matchers do not count it as unexpected.

Pass `visible: :all` to a call to take hidden elements too:

```ruby
form.field(:notes, visible: :all)
filters.filter(:email, visible: :all)
show.attributes_table.row(:email, visible: :all)
show.attributes_table.value(:email, visible: :all)
index.table.row(customer.id).cell(:email, visible: :all)
expect(form).to have_field_error(:email, "is invalid", visible: :all)
expect(form).to have_exact_fields(visible: :all)
form.exact_mismatches(visible: :all)
```

Or declare the element with `visible: :all`, for example a field that a script hides and shows:

```ruby
section :form, ActiveAdminPageObjects::Form do
  field :email, "Email", ActiveAdminPageObjects::Form::StringField
  field :notes, "Notes", ActiveAdminPageObjects::Form::StringField, visible: :all
end

form.field(:notes) # found when it is hidden too
expect(form).to have_exact_fields # passes with the notes field hidden or shown
```

- `row`, `column`, `filter` and `field` take `visible:`. Every lookup and matcher then finds that element with it.
- `visible:` on a call overrides the declaration: `form.field(:notes, visible: :visible)`. It takes Capybara's values: `:all`, `:hidden`, `:visible`, `true` and `false`.
- On a matcher, `visible:` applies to every element: the declared ones and the ones that are not declared.
- `have_exact_field_errors` has no `visible:` option, because its keywords are field names. It counts the errors of the visible fields and of the fields declared with `visible:`.
- `value(key, visible: :all)` returns the DOM text: a hidden cell has no visible text.
- `visible:` finds the element itself. A section still looks for its own controls as Capybara does by default, so `fill` and `value` of a hidden text field raise `Capybara::ElementNotFound`.
- The `<select>` inside a visible field or filter is a control like any other: hidden or marked `aria-hidden="true"`, as a JavaScript select widget leaves it, it is not found. See [Hidden selects](#hidden-selects).

### Failure messages

RSpec's own `have_` matcher only reports that the predicate returned false. Include `ActiveAdminPageObjects::RSpec::Matchers` to get a message that lists what differs:

```ruby
require "active_admin_page_objects/rspec"

RSpec.configure do |config|
  config.include ActiveAdminPageObjects::RSpec::Matchers
end

expect(show.attributes_table).to have_exact_rows(except: :notes)
```

`active_admin_page_objects/rspec` requires `rspec/expectations`. The gem does not depend on it: your suite's `rspec` or `rspec-rails` provides it.

```
expected exactly the declared rows (except: notes), but:
  missing: secret
  unexpected: email, status
  label of external_id: expected "External id", got "External ID"
```

- The module defines `have_declared_rows`, `have_declared_columns`, `have_declared_filters`, `have_declared_fields`, `have_exact_rows`, `have_exact_columns`, `have_exact_filters`, `have_exact_fields` and the `have_no_` form of each. They call the same predicates with the same options, so specs need no change.
- `missing` lists the declared names the page lacks. `unexpected` lists the elements on the page that are not declared; only the exact matchers have it. Each `label of` line gives the declared label and the label found.
- The message names the `only:`, `except:` and `visible:` options given.
- A `have_no_` matcher that fails has nothing to list: `expected the rows to differ from the declared ones, but they match exactly`.
- `not_to have_exact_rows` calls `has_no_exact_rows?`, so it waits for the page to differ.
- On an object that declares nothing, each one is RSpec's predicate matcher.

The module also defines `have_exact_field_errors`, `have_exact_semantic_errors` and their `have_no_` forms, for a form:

```ruby
expect(form).to have_exact_field_errors(name: "is reserved", notes: "is too long")
expect(form).to have_exact_semantic_errors("Balance is negative", "Name is reserved", strict_order: true)
```

```
expected exactly the given field errors, but:
  name: missing "is reserved"; unexpected "can't be blank"
  notes: missing "is too long"
  email: unexpected "is invalid"
```

```
expected exactly the given semantic errors, in order, but:
  order: expected "Balance is negative", "Name is reserved", got "Name is reserved", "Balance is negative"
```

- Field errors have one line per field that differs. `missing` lists the expected messages the field does not show. `unexpected` lists the messages it shows that were not expected. A field that was not expected has only `unexpected`.
- Semantic errors have a `missing` and an `unexpected` line. With `strict_order: true` and the same messages in another order, the `order` line gives both orders.
- Without arguments the message starts with `expected no field errors` or `expected no semantic errors`.
- A `have_no_` matcher that fails says that the errors match exactly, or that the form shows no error when no arguments were given.

The module also defines the [matchers shared with capybara_active_admin](#matchers-shared-with-capybara_active_admin). Include it after that gem's matchers.

### Mismatches

Without the module, ask the section what differs:

```ruby
index.table.declared_label_mismatches # => { "external_id" => "External Id", "secret" => nil }
index.table.exact_mismatches
# => { missing: ["secret"], unexpected: ["email"], labels: { "external_id" => "External Id" } }
```

`declared_label_mismatches` returns each failing name with the label found, or `nil` when the page has no such element. `exact_mismatches` splits them into `missing` and `labels`, and adds `unexpected`: the keys of the elements on the page that are not declared. Both take `only:`, `except:` and `visible:`.

`last_mismatches` returns what the last label or exact matcher found on its last try, in the form of `exact_mismatches`. `last_field_errors` and `last_semantic_errors` return the errors the last `have_exact_field_errors` or `have_exact_semantic_errors` found.

### Strict names

A section that declares anything raises `ArgumentError` for every other name, before it queries the page. The message gives the name and lists the declared ones. A section without declarations takes any key, as before.

- `AttributesTable`: `has_row?`, `has_no_row?`, `row` and `value`.
- `Table`: its rows' `cell`, `has_cell?` and `has_no_cell?`.
- `Filters`: `filter`.
- `Form`: `field`, `fill`, `has_field_error?`, `has_no_field_error?`, `has_exact_field_errors?`, `has_no_exact_field_errors?`, `has_disabled_field?`, `has_enabled_field?` and their `has_no_` forms.

Filters and fields take the declared name: `form.field(:name)` and `have_field_error(:name)`.

Names compare as everywhere else: `:external_id`, `"external_id"` and `"External ID"` are the same name.

## Matchers shared with capybara_active_admin

[capybara_active_admin](https://github.com/activeadmin-plugins/capybara_active_admin) defines RSpec matchers for Capybara's `page`, such as `have_page_title`, `have_table` and `have_semantic_errors`. In an example group that includes them, they replace the predicate matchers of the page objects: `expect(index).to have_page_title(text: "Customers")` calls the matcher of that gem.

`ActiveAdminPageObjects::RSpec::Matchers` defines the same names for both. Include it after capybara_active_admin's matchers, so it takes precedence. The module also gives the label and exact matchers their [failure messages](#failure-messages).

```ruby
require "capybara/active_admin/rspec" # includes that gem's matchers
require "active_admin_page_objects/rspec"

RSpec.configure do |config|
  config.include ActiveAdminPageObjects::RSpec::Matchers
end
```

- On a SitePrism page or section that has the predicate, such as `has_page_title?`, the matcher calls it, like RSpec's own `have_` matchers. Negated, it calls `has_no_page_title?` when the object has it.
- Capybara's own `has_table?` does not count as such a predicate. `have_table` calls the page object only when it defines `has_table?` itself, as a page with `section :table` does.
- On anything else, such as Capybara's `page`, it is the matcher of the module included before.

It covers the matchers of capybara_active_admin 1.0.0: `have_action_item`, `have_action_item_link`, `have_attribute_row`, `have_attributes_table`, `have_batch_action`, `have_fields_date_range`, `have_flash_message`, `have_footer`, `have_form_error`, `have_has_many_fields_for`, `have_no_form_errors`, `have_page_title`, `have_panel`, `have_semantic_error`, `have_semantic_errors`, `have_sidebar`, `have_status_tag`, `have_submit_input`, `have_table`, `have_table_cell`, `have_table_header`, `have_table_row`, `have_table_scope` and `have_table_scopes`.

## JavaScript driver

These need a JavaScript driver such as Cuprite or Selenium:

- `BatchActions#apply`: ActiveAdmin's JavaScript opens the menu and submits the form.
- `StringFilter#fill_in` and `NumericFilter#fill_in` with a predicate other than the selected one: the JavaScript renames the input when the predicate changes.

Everything else works with `rack_test` too, including `MainMenu#go` and `MainMenu#click`, filters with the current predicate, plain selects, date ranges, scopes, pagination and forms.

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

To use your own field or filter class, declare it on the section: `field :status, "Status", MySelectField`. It is a subclass of the gem's class for that input, or of `ActiveAdminPageObjects::Form::Field` or `ActiveAdminPageObjects::Filter` for an input class the gem has no class for. See [Declared types](#declared-types).

### Select widgets

`ActiveAdminPageObjects::SelectControl` drives a visible native `<select>` for `SelectFilter` and `Form::Field`. For a widget on some selects, declare your own class: see [Hidden selects](#hidden-selects). A gem that renders a JavaScript select widget for every select prepends a module into `SelectControl` instead. It overrides the private methods `choose_option(scope, label)`, `option_offered?(scope, label)`, `control_disabled?(scope)` and `chosen_item?(scope, label)`, and `native_select_visibility` for the methods that still read the hidden `<select>`:

```ruby
module MyWidget
  module SelectControl
    private

    def choose_option(scope, label)
      # open the widget and click the option
    end

    def native_select_visibility
      :all
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
ActiveAdminPageObjects.check_version!(">= 2.0.0.a", "< 3.0.0.a", plugin: "my_plugin")

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
