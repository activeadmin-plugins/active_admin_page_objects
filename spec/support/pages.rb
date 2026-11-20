# frozen_string_literal: true

# Page objects for the dummy app, written the way an app writes its own. The
# customer pages declare their labels; the order and tag pages do not.
module Pages
  class Dashboard < ActiveAdminPageObjects::Page
    set_url "/admin/dashboard"

    section :welcome, ActiveAdminPageObjects::Panel, :active_admin_panel, "Welcome"
  end

  class CustomerIndex < ActiveAdminPageObjects::Page
    set_url "/admin/customers{?query*}"

    section :table, ActiveAdminPageObjects::Table do
      column :id, "Id"
      column :name, "Name"
      column :email, "Email"
      column :external_id, "External ID"
      column :status, "Status"
      column :balance, "Balance"
      column :active, "Active"
      column :category, "Category"
      column :created, "Created"
    end
    section :filters, ActiveAdminPageObjects::Filters do
      filter :name, "Name", ActiveAdminPageObjects::StringFilter
      filter :email, "Email"
      filter :external_id, "External ID"
      filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
      filter :status, "Status", ActiveAdminPageObjects::SelectFilter
      filter :category, "Category"
      filter :active, "Active", ActiveAdminPageObjects::BooleanFilter
      filter :created_at, "Created at"
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
      row :signed_up, "Signed Up"
    end
    section :notes, ActiveAdminPageObjects::Panel, :active_admin_panel, "Notes"
    section :tabs, ActiveAdminPageObjects::Tabs
  end

  class CustomerForm < ActiveAdminPageObjects::Page
    set_url "/admin/customers{/id}{/action}"

    section :form, ActiveAdminPageObjects::Form do
      field :name, "Name", ActiveAdminPageObjects::Form::StringInput
      field :email, "Email"
      field :external_id, "External ID"
      field :status, "Status", ActiveAdminPageObjects::Form::SelectInput
      field :category, "Category"
      field :balance, "Balance"
      field :active, "Active", ActiveAdminPageObjects::Form::BooleanInput
      field :notes, "Notes"
      field :website, "Website"
      field :phone, "Phone"
      field :password, "Password"
      field :tier, "Tier", ActiveAdminPageObjects::Form::RadioInput
      field :channels, "Channels", ActiveAdminPageObjects::Form::CheckBoxesInput
      field :signed_on, "Signed on", ActiveAdminPageObjects::Form::DatePickerInput
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
