# active_admin_page_objects

A Page Object Model DSL for Capybara of ActiveAdmin, built on [SitePrism](https://github.com/site-prism/site_prism).

System specs call semantic methods, such as `table.row(id).cell(:name)`, `filters.filter(:status).select_option("Active")` or `main_menu.go("Catalog", "Orders")`, instead of CSS selectors. The selectors for vanilla ActiveAdmin 3 live in this gem.

## Versions

- 1.x supports vanilla ActiveAdmin 3 (tested on 3.5.2). This is the `1-x-stable` branch.
- 2.x supports vanilla ActiveAdmin 4. This is the `main` branch. Its sections and methods have the same names as 1.x where the component exists in both versions.

To upgrade ActiveAdmin from 3 to 4, bump this gem to 2.x. Only specs that use a feature ActiveAdmin 4 removed need a change: `Tabs`, the action-item dropdown and `UtilityNavigation` raise `RemovedInActiveAdmin4` in 2.x.

## Installation

Until the first release, install it from git:

```ruby
# Gemfile
group :test do
  gem "active_admin_page_objects", github: "senid231/active_admin_page_objects", branch: "1-x-stable"
end
```

```ruby
# spec/rails_helper.rb, or a file in spec/support
require "active_admin_page_objects"
```

Runtime dependencies: `activeadmin` (>= 3.0, < 4.0.0.a), `site_prism` (>= 5.0, < 7) and `capybara` (>= 3.37).

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
expect(page_object).to have_blank_slate(text: "There are no Customers yet.")
page_object.panel("Notes").body # the panel titled "Notes"
page_object.sidebar("Help").body # the sidebar section titled "Help"
page_object.modal_dialog # see Batch actions
```

ActiveAdmin 3 has no dark mode toggle and no user menu button. `dark_mode_toggle` (alias `theme_switcher`) and `user_menu_button` raise `ActiveAdminPageObjects::NotInActiveAdmin3`.

`panel` skips sidebar sections and the comments panel, which ActiveAdmin 3 renders as panels too. Use `sidebar` and `Comments` for them.

### Utility navigation

The current user and the logout link in the header.

```ruby
navigation = page_object.utility_navigation
navigation.current_user # => "admin@example.com"
navigation.labels # => ["admin@example.com", "Logout"]
navigation.logout
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
page_object.action_items.labels # => ["New Customer", "More"]
page_object.action_items.click("New Customer")
expect(page_object.action_items).to have_item("More")
```

ActiveAdmin 3 always renders the container, so assert on its items, not on the section.

A `dropdown_menu` is an item too. `dropdown(label)` returns a `DropdownMenu` (the only one when called without a label):

```ruby
more = page_object.action_items.dropdown("More")
more.label # => "More"
more.labels # => ["Report", "Customers"], also from a closed menu
more.open
more.click("Customers") # opens the menu first
expect(more).to have_item("Report")
```

### Flashes

ActiveAdmin 3 renders the `notice`, `alert`, `error` and `warning` types. It renders the container on every page, so assert on the content: `have_no_flash` works without flashes.

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

Cells are keyed by column: `:external_id` or `"External ID"` both match the `col-external_id` class. `have_header_names` takes every header in order and compares case-insensitively, so `"Id"` and `"ID"` match. To check the exact labels, declare the columns: see [Declared labels](#declared-labels).

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
row.status_tag(:status) # see Status tags
table.rows.map(&:record_id)
```

Sorting reads and clicks the header links:

```ruby
table.sort_by(:name) # one click
table.sort_by(:name, :asc) # clicks until the column is sorted that way
table.sorted_by # => ["name", :asc], or nil
expect(table).to have_sortable_column(:name)
```

The first click on an unsorted column sorts descending.

The section defaults to `table.data-table`. Pass a locator for another table, such as a `table_for` inside a panel: `section :orders, ActiveAdminPageObjects::Table, "#orders_panel table"`.

### Attributes table

Rows are keyed by the `row :foo` symbol, or by the label parameterized with `_`.

```ruby
table = show.attributes_table
expect(table).to have_row(:name, exact_text: "Acme")
expect(table).to have_no_row(:secret)
table.row(:category) # the <tr>
table.value(:email) # => "acme@example.com"
table.status_tag(:status) # see Status tags
```

### Status tags

An index row and the attributes table of a show page match the status tag of a cell by its label and, with `type:`, its CSS classes:

```ruby
expect(index.table.row(customer.id)).to have_status_tag(:status, "Pending")
expect(show.attributes_table).to have_status_tag(:status, "Pending", type: "pending")
expect(show.attributes_table).to have_no_status_tag(:status, "Active")
```

`status_tag(key)` returns the `StatusTag`:

```ruby
tag = show.attributes_table.status_tag(:status)
tag.label # => "Pending"
tag.type # => "pending", or "ok warning" for several classes
expect(tag).to have_type("pending")
expect(tag).to have_label("pending")
```

`label` returns the DOM text. ActiveAdmin 3's CSS uppercases it on screen. The matchers ignore the case of the label.

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

A sidebar section works the same way, with `ActiveAdminPageObjects::Sidebar` and the `:active_admin_sidebar` selector: `section :help, ActiveAdminPageObjects::Sidebar, :active_admin_sidebar, "Help"`.

`links` lists the links of the body, each with its text and its `href` attribute as the page wrote it, on every driver.

### Comments

```ruby
class CustomerShow < ActiveAdminPageObjects::Page
  set_url "/admin/customers/{id}"

  section :comments, ActiveAdminPageObjects::Comments
end

comments = show.comments
comments.add("Called back")
expect(comments).to have_comment("Called back")
comments.count # => 1, from the "Comments (1)" title
comments.bodies # => ["Called back"]
comments.authors # => ["admin@example.com"]
comments.delete("Called back") # accepts the browser confirmation
```

### Filters

`filter(key)` returns the section typed by the filter input: `StringFilter`, `NumericFilter`, `SelectFilter`, `BooleanFilter` or `DateRangeFilter`. The key is the one given to `filter :key`; the section wraps `#q_<key>_input`. Filters that [declare their filters](#declared-labels) take the declared name and have a method per filter: `filters.balance`.

```ruby
filters = index.filters
filters.filter(:name).fill_in(with: "Acme", predicate: "Equals") # or predicate: :eq
filters.filter(:balance).fill_in(with: 100, predicate: :gt)
filters.filter(:status).select_option("Active")
filters.filter(:active).set(true) # false, or nil for "Any"
filters.filter(:created_at).set("2026-01-01", Date.new(2026, 1, 31))
filters.submit
filters.clear # needs a JavaScript driver

expect(filters.filter(:name)).to have_value("Acme", predicate: "Equals")
expect(filters.filter(:status)).to have_selected("Active")
expect(filters.filter(:active)).to have_value(true)
expect(filters.filter(:created_at)).to have_range("2026-01-01", "2026-01-31")
```

`DateRangeFilter` types the dates into the two inputs. It does not use the jQuery UI datepicker.

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

Actions are found by label (`"Delete Selected"`) or by name (`:destroy`). `apply(label, inputs = {})` opens the menu and clicks the action. An action with `confirm:` or `form:` opens ActiveAdmin's modal dialog: `apply` sets each of `inputs` by field name and clicks OK.

```ruby
index.table.row(customer.id).select
index.batch_actions.select_all
index.batch_actions.apply(:destroy)
index.batch_actions.apply("Set Status Selected", status: "pending")
expect(index.batch_actions).to have_action("Flag Selected")
```

### Modal dialog

`page.modal_dialog` is the dialog ActiveAdmin opens for batch actions. Use it to drive the dialog yourself, for example to cancel:

```ruby
dialog = index.modal_dialog
dialog.title # => "Are you sure you want to do this?"
dialog.fill("status", with: "pending") # input or select, by field name
expect(dialog).to have_field("status")
dialog.confirm # or dialog.cancel
expect(index).to have_no_modal_dialog
```

### Form

Fields are named by attribute, as in `f.input :email`. A form that [declares its fields](#declared-labels) takes the declared names and has a method per field: `form.email`.

```ruby
form = form_page.form # section :form, ActiveAdminPageObjects::Form
form.field(:email).fill("acme@example.com")
form.fill_fields(name: "Acme", category: "Retail", active: false) # in this order
form.submit
```

`field(name)` returns the section typed by the formtastic input class. `fill(value)` sets the field the way its type needs.

- `Form::StringField` for `string`, `email`, `url`, `phone`, `password`, `number` and `text`: `fill` types the value. `value`.
- `Form::SelectField` for `select`: `fill` picks the option with that label. `options` (without the blank option) and `selected`.
- `Form::BooleanField` for `boolean`: `fill(true)` ticks the checkbox and `fill(false)` unticks it. `checked?`.
- `Form::RadioField` for `radio`: `fill` picks the radio button with that label. `options` and `selected`.
- `Form::CheckBoxesField` for `check_boxes`: `fill` takes an array of labels, ticks them and unticks the others. `check(*labels)`, `uncheck(*labels)` and `checked`.
- `Form::DatePickerField` for `datepicker`: `fill` takes a Date or a string and types it in. It does not use the jQuery UI datepicker.
- `Form::Field` for any other class: `fill` types text, picks a select option or ticks a checkbox, by what the wrapper holds.

Every field also has `errors`, and `choose(option)` for a select or a radio button.

```ruby
form.field(:status).options # => ["active", "pending", "closed"]
form.field(:status).selected # => "pending", or nil for the blank option
expect(form.field(:active)).to be_checked
form.field(:tier).selected # => "Gold", the chosen radio button
form.field(:channels).fill(%w[Email Post])
form.field(:channels).checked # => ["Email", "Post"]
form.field(:signed_on).fill(Date.new(2026, 1, 31))
```

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

- `have_field_errors` and `have_no_field_errors` look at the whole form, has_many fieldsets included.
- `have_exact_field_errors` takes each field with its message, or an array of messages. Every one of these fields shows exactly these messages, and no other field shows an error. Without arguments it passes when no field shows an error. It leaves out the fields of has_many fieldsets: ask each fieldset. Its keywords are field names, so it takes no Capybara options.
- `have_exact_semantic_errors` compares the base errors exactly and case-sensitively: the same messages, in any order. `strict_order: true` compares the order too. Without messages it passes when the form shows no base error.
- `have_no_exact_field_errors` and `have_no_exact_semantic_errors` wait until the errors differ.

### Has many

`form.has_many(association)` returns a `HasMany` for a `has_many` block. Fieldsets are 0-based. A fieldset has the field methods of the form: `field`, `fill_fields` and the field error matchers.

```ruby
orders = form.has_many(:orders)
orders.heading # => "Orders"
orders.count # => 2
expect(orders).to have_fieldsets(count: 2)

fieldset = orders.add # clicks the add link, returns the new fieldset
fieldset.fill_fields(reference: "REF-NEW", state: "shipped")
orders.fieldset(0).field(:quantity).value # => "2"
expect(orders.fieldset(0)).to have_exact_field_errors(quantity: "must be greater than 0")
orders.remove(2) # a new fieldset: its remove link
orders.remove(0) # a saved one: ticks its delete checkbox
expect(orders.fieldset(0)).to be_marked_for_destroy
```

Declare the block on the form to get `form.orders` and a method per fieldset field: see [Declared has_many blocks](#declared-has_many-blocks).

### Tabs

```ruby
class CustomerShow < ActiveAdminPageObjects::Page
  section :tabs, ActiveAdminPageObjects::Tabs
end

show.tabs.labels # => ["Overview", "Orders"]
show.tabs.switch("Orders")
show.tabs.current # => "Orders", or nil before jQuery UI sets the tabs up
expect(show.tabs.body).to have_text("Order list")
expect(show.tabs).to have_tab("Orders")
```

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
- `filter(name, label, type, attribute: name)` and `field(name, label, type, attribute: name)` need the label and the section class.

SitePrism 5 and 6 turn the block into a subclass of the section class. A named subclass takes the same lines in its class body. A subclass inherits the declarations of its superclass and adds its own.

### Accessors

`filter` and `field` define a method of the declared name on the section. It returns `filter(name)` or `field(name)`:

```ruby
index.filters.balance.fill_in(with: 100, predicate: :gt)
form_page.form.status.fill("pending")
```

The declaration raises `ArgumentError` when the section already has a method of that name, public or private, its own or inherited. SitePrism sections have `name`, `title`, `text` and `select`, among others. Give the element another name and pass its attribute:

```ruby
field :customer_name, "Name", ActiveAdminPageObjects::Form::StringField, attribute: :name
filter :customer_name, "Name", ActiveAdminPageObjects::StringFilter, attribute: :name
```

`attribute:` is the key in the wrapper id: `:name` for `#customer_name_input` and for `#q_name_input`. A subclass can declare an inherited name again. Rows and columns get no method and take no `attribute:`.

### Declared types

`filters.filter(name)` and `form.field(name)` return an instance of the declared class. An app can declare its own subclass, such as a `Select2Field < ActiveAdminPageObjects::Form::SelectField`.

The declared class must be the class the gem detects for the wrapper, or a subclass of it. Otherwise the lookup raises `Capybara::ExpectationNotMet`, and the message names both classes. A section without declarations returns the detected class.

### Declared has_many blocks

`has_many(name, heading, attribute: name, &block)` declares a `has_many` block of a form. The form gets a method of that name, which returns the `HasMany`. The block declares the fields of a fieldset, by the same rules, and each fieldset gets a method per field.

```ruby
section :form, ActiveAdminPageObjects::Form do
  field :email, "Email", ActiveAdminPageObjects::Form::StringField
  has_many :gateways, "Gateways" do
    field :gateway, "Gateway", ActiveAdminPageObjects::Form::SelectField, attribute: :gateway_id
  end

  def add_gateway(name)
    gateways.add.gateway.fill(name)
  end
end

form.gateways.add.gateway # the SelectField of the new fieldset
form.gateways.fieldset(0).gateway.selected
expect(form.gateways.fieldsets).to all(have_exact_fields)
```

- `heading` is the text of the block's `h3`. The form's label matchers compare it. Pass `nil` when the form uses `heading: false`.
- `attribute:` is the association, when the name differs from it.
- A form that declares has_many blocks raises `ArgumentError` from `has_many(association)` for any other association.

### Label matchers

`have_declared_columns`, `have_declared_filters`, `have_declared_rows` and `have_declared_fields` pass when every declared element is on the page with exactly its label. The comparison is exact and case-sensitive, so `"External id"` does not match `"External ID"`. Only whitespace is normalized.

- CSS `text-transform` does not change the result, on any driver.
- In filter and form labels, the text of links, buttons and `abbr` elements is not part of the label. That drops the required marker (`*`) and controls that plugins append, such as the date range preset's "Set range" link.
- `have_declared_fields` on a form also compares the headings of the declared has_many blocks. The fields of a fieldset are compared on the fieldset.
- The order is not checked. Elements that are on the page but not declared are ignored: the exact matchers catch those.
- They wait like the other matchers. `have_no_declared_columns` and the other three wait until a label differs.
- They raise `ArgumentError` on a section that declares nothing.

### Exact matchers

`have_exact_columns`, `have_exact_filters`, `have_exact_rows` and `have_exact_fields` pass when the label matcher passes and the page has no other element of that kind:

- Rows: the `tr.row-*` of the attributes table.
- Columns: the `th.col-*` of the table, the untitled selection and actions columns included.
- Filters: the filter wrappers of the filter form.
- Form fields: the input wrappers outside the has_many blocks, and each has_many block. Hidden inputs are not fields.
- Fieldset fields: the input wrappers of the fieldset. The delete checkbox and a has_many block nested in the fieldset are left out.

`have_no_exact_columns` and the other three wait until the page differs.

### only and except

The label matchers and the exact matchers take `only:` and `except:`: a declared name, or an array of them. A name that is not declared raises `ArgumentError`.

```ruby
expect(index.table).to have_exact_columns(except: :notes) # a column that only some users see
expect(form_page.form).to have_declared_fields(only: %i[email status])
```

- `only:` checks these elements and ignores the rest of the page, so no element is unexpected.
- `except:` skips these elements: the page may have them or not.

### Mismatches

When a matcher fails, ask the section what differs:

```ruby
index.table.declared_label_mismatches # => { "external_id" => "External Id", "secret" => nil }
index.table.exact_mismatches
# => { missing: ["secret"], unexpected: ["email"], labels: { "external_id" => "External Id" } }
```

`declared_label_mismatches` returns each failing name with the label found, or `nil` when the page has no such element. `exact_mismatches` splits them into `missing` and `labels`, and adds `unexpected`: the keys of the elements on the page that are not declared. Both take `only:` and `except:`.

### Strict names

A section that declares anything raises `ArgumentError` for every other name, before it queries the page. The message gives the name and lists the declared ones. A section without declarations takes any key, as before.

- `AttributesTable`: `has_row?`, `has_no_row?`, `row`, `value`, `status_tag`, `has_status_tag?` and `has_no_status_tag?`.
- `Table`: `sort_by` and `has_sortable_column?`. Its rows: `cell`, `has_cell?`, `has_no_cell?`, `status_tag`, `has_status_tag?` and `has_no_status_tag?`.
- `Filters`: `filter`.
- `Form` and the fieldsets of a declared has_many: `field`, `fill_fields`, `has_field_error?`, `has_no_field_error?`, `has_exact_field_errors?` and `has_no_exact_field_errors?`.

Filters and fields take the declared name, not the attribute: `form.field(:customer_name)` and `have_field_error(:customer_name)`.

Names compare as everywhere else: `:external_id`, `"external_id"` and `"External ID"` are the same name.

## Matchers shared with capybara_active_admin

[capybara_active_admin](https://github.com/activeadmin-plugins/capybara_active_admin) defines RSpec matchers for Capybara's `page`, such as `have_page_title`, `have_table` and `have_status_tag`. In an example group that includes them, they replace the predicate matchers of the page objects: `expect(index).to have_page_title(text: "Customers")` calls the matcher of that gem.

`ActiveAdminPageObjects::RSpec::Matchers` defines the same names for both. Include it after capybara_active_admin's matchers, so it takes precedence:

```ruby
require "capybara/active_admin/rspec" # includes that gem's matchers
require "active_admin_page_objects/rspec"

RSpec.configure do |config|
  config.include ActiveAdminPageObjects::RSpec::Matchers
end
```

- On a SitePrism page or section that has the predicate, such as `has_page_title?`, the matcher calls it, like RSpec's own `have_` matchers. Negated, it calls `has_no_page_title?` when the object has it.
- On anything else, such as Capybara's `page`, it is the matcher of the module included before.

It covers the matchers of capybara_active_admin 1.0.0: `have_action_item`, `have_action_item_link`, `have_attribute_row`, `have_attributes_table`, `have_batch_action`, `have_fields_date_range`, `have_flash_message`, `have_footer`, `have_form_error`, `have_has_many_fields_for`, `have_no_form_errors`, `have_page_title`, `have_panel`, `have_semantic_error`, `have_semantic_errors`, `have_sidebar`, `have_status_tag`, `have_submit_input`, `have_table`, `have_table_cell`, `have_table_header`, `have_table_row`, `have_table_scope` and `have_table_scopes`.

## JavaScript driver

These need a JavaScript driver such as Cuprite or Selenium:

- `BatchActions#apply` and `ModalDialog`: ActiveAdmin's JavaScript opens the menu and the dialog and submits the form.
- `Filters#clear` and `FiltersFooter#clear`: the "Clear Filters" link is `href="#"`.
- `Tabs#switch` and `Tabs#current`: jQuery UI switches the tabs. Without JavaScript every tab body is shown.
- `DropdownMenu#open` and `#click`: the button toggles the menu. Without JavaScript the list is always shown.
- `HasMany#add` and `#remove`: the JavaScript adds and removes the fieldsets.
- `Comments#delete`: the link asks the browser to confirm.
- `StringFilter#fill_in` and `NumericFilter#fill_in` with a predicate other than the selected one: the JavaScript renames the input when the predicate changes.

Everything else works with `rack_test` too, including `MainMenu#go`, filters with the current predicate, plain selects, date ranges, scopes, pagination, sorting and forms.

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

`register_selectors` also replaces a key of the gem, for example a theme's own `main_menu`.

Add a section or an element to every page that includes `Layout`, including page classes defined earlier:

```ruby
ActiveAdminPageObjects::Layout.add_section(:audit_panel, AuditPanel)
ActiveAdminPageObjects::Layout.add_element(:banner, ".banner")
```

Register a section for a custom filter input class with `ActiveAdminPageObjects::Filters.register_type("my_input", MyFilter)`, and for a custom form input class with `ActiveAdminPageObjects::Form.register_type("my_input", MyField)`. `MyField` subclasses `ActiveAdminPageObjects::Form::Field`.

### Select widgets

`ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter` and `Form::Field`. A gem with a JavaScript select widget prepends a module into it and overrides the private methods `choose_option(scope, label)`, `option_offered?(scope, label)`, `control_disabled?(scope)` and `chosen_item?(scope, label)`:

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
ActiveAdminPageObjects.check_version!(">= 1.0.0.a", "< 2", plugin: "my_plugin")

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
bundle exec rspec
BUNDLE_GEMFILE=gemfiles/site_prism_5.gemfile bundle exec rspec
bundle exec rubocop
```

The specs drive a Rails 8 dummy app with ActiveAdmin 3.5.2 (`spec/dummy`) through headless Chrome with Cuprite. The dummy app uses sprockets and dartsass-sprockets, so it needs no Node.

## License

MIT
