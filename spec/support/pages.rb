# frozen_string_literal: true

# Page objects for the dummy app, written the way an app writes its own. The
# customer pages declare their elements; the order and tag pages do not.
# SitePrism::Section#name is taken, so the `name` filter and field are
# declared as `customer_name`.
module Pages
  class Dashboard < ActiveAdminPageObjects::Page
    set_url "/admin/dashboard"

    section :welcome, ActiveAdminPageObjects::Panel, :active_admin_panel, "Welcome"
  end

  class CustomerIndex < ActiveAdminPageObjects::Page
    set_url "/admin/customers{?query*}"

    section :table, ActiveAdminPageObjects::Table do
      column :selectable, ""
      column :id, "Id"
      column :name, "Name"
      column :email, "Email"
      column :external_id, "External ID"
      column :status, "Status"
      column :balance, "Balance"
      column :active, "Active"
      column :category, "Category"
      column :created, "Created"
      column :notes, "Notes"
      column :actions, ""
    end
    section :filters, ActiveAdminPageObjects::Filters do
      filter :customer_name, "Name", ActiveAdminPageObjects::StringFilter, attribute: :name
      filter :email, "Email", ActiveAdminPageObjects::StringFilter
      filter :external_id, "External ID", ActiveAdminPageObjects::StringFilter
      filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
      filter :status, "Status", ActiveAdminPageObjects::SelectFilter
      filter :category, "Category", ActiveAdminPageObjects::SelectFilter
      filter :active, "Active", ActiveAdminPageObjects::BooleanFilter
      filter :created_at, "Created at", ActiveAdminPageObjects::DateRangeFilter
    end
    section :filters_footer, ActiveAdminPageObjects::FiltersFooter
    section :name_filter, ActiveAdminPageObjects::StringFilter, "#q_name_input"
    section :scopes, ActiveAdminPageObjects::Scopes
    section :pagination, ActiveAdminPageObjects::Pagination
    section :batch_actions, ActiveAdminPageObjects::BatchActions
  end

  class CustomerShow < ActiveAdminPageObjects::Page
    set_url "/admin/customers/{id}"

    section :attributes_table, ActiveAdminPageObjects::AttributesTable do
      row :name, "Name"
      row :email, "Email"
      row :external_id, "External ID"
      row :status, "Status"
      row :balance, "Balance"
      row :category, "Category"
      row :signed_up, "Signed up"
    end
    section :notes, ActiveAdminPageObjects::Panel, :active_admin_panel, "Notes"
    section :tabs, ActiveAdminPageObjects::Tabs
  end

  class CustomerForm < ActiveAdminPageObjects::Page
    set_url "/admin/customers{/id}{/action}"

    section :form, ActiveAdminPageObjects::Form do
      field :customer_name, "Name", ActiveAdminPageObjects::Form::StringField, attribute: :name
      field :email, "Email", ActiveAdminPageObjects::Form::StringField
      field :external_id, "External ID", ActiveAdminPageObjects::Form::StringField
      field :status, "Status", ActiveAdminPageObjects::Form::SelectField
      field :category, "Category", ActiveAdminPageObjects::Form::SelectField
      field :balance, "Balance", ActiveAdminPageObjects::Form::StringField
      field :active, "Active", ActiveAdminPageObjects::Form::BooleanField
      field :notes, "Notes", ActiveAdminPageObjects::Form::StringField
      field :website, "Website", ActiveAdminPageObjects::Form::StringField
      field :phone, "Phone", ActiveAdminPageObjects::Form::StringField
      field :password, "Password", ActiveAdminPageObjects::Form::StringField
      field :tier, "Tier", ActiveAdminPageObjects::Form::RadioField
      field :channels, "Channels", ActiveAdminPageObjects::Form::CheckBoxesField
      field :signed_on, "Signed on", ActiveAdminPageObjects::Form::DatePickerField
    end
  end

  class OrderIndex < ActiveAdminPageObjects::Page
    set_url "/admin/orders"

    section :table, ActiveAdminPageObjects::Table
    section :filters, ActiveAdminPageObjects::Filters
  end

  class TagIndex < ActiveAdminPageObjects::Page
    set_url "/admin/tags"

    section :table, ActiveAdminPageObjects::Table
  end
end
