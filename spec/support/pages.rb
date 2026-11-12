# frozen_string_literal: true

# Page objects for the dummy app, written the way an app writes its own.
module Pages
  class Dashboard < ActiveAdminPageObjects::Page
    set_url "/admin/dashboard"

    section :welcome, ActiveAdminPageObjects::Panel, :active_admin_panel, "Welcome"
  end

  class CustomerIndex < ActiveAdminPageObjects::Page
    set_url "/admin/customers{?query*}"

    section :table, ActiveAdminPageObjects::Table do
      self.default_header_names = %w[Id Name Email Status Balance Active Category Created]
    end
    section :filters, ActiveAdminPageObjects::Filters
    section :filters_footer, ActiveAdminPageObjects::FiltersFooter
    section :name_filter, ActiveAdminPageObjects::StringFilter, "#q_name_input"
    section :scopes, ActiveAdminPageObjects::Scopes
    section :pagination, ActiveAdminPageObjects::Pagination
    section :batch_actions, ActiveAdminPageObjects::BatchActions
  end

  class CustomerShow < ActiveAdminPageObjects::Page
    set_url "/admin/customers/{id}"

    section :attributes_table, ActiveAdminPageObjects::AttributesTable
    section :notes, ActiveAdminPageObjects::Panel, :active_admin_panel, "Notes"
    section :tabs, ActiveAdminPageObjects::Tabs
  end

  class CustomerForm < ActiveAdminPageObjects::Page
    set_url "/admin/customers{/id}{/action}"

    section :form, ActiveAdminPageObjects::Form
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
