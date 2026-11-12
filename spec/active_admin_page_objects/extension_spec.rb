# frozen_string_literal: true

RSpec.describe "Extending sections" do
  let(:customer) { create_customer(name: "Acme") }

  it "adds methods to rows through a module" do
    row_extension = Module.new do
      def name_text
        cell(:name).text
      end
    end
    row_class = Class.new(ActiveAdminPageObjects::Table::Row) { include row_extension }
    table_class = Class.new(ActiveAdminPageObjects::Table) do
      sections :rows, row_class, :active_admin, :table_row
    end
    page_class = Class.new(ActiveAdminPageObjects::Page) do
      set_url "/admin/customers"
      section :table, table_class
    end

    customer
    index = page_class.new
    index.load
    expect(index.table.rows.map(&:name_text)).to eq(["Acme"])
  end

  it "subclasses a section with its own selector" do
    panel_class = Class.new(ActiveAdminPageObjects::Panel) do
      def paragraphs
        body.all("p").map(&:text)
      end
    end
    page_class = Class.new(ActiveAdminPageObjects::Page) do
      set_url "/admin/dashboard"
      section :stats, panel_class, :active_admin_panel, "Stats"
    end
    dashboard = page_class.new
    dashboard.load
    expect(dashboard.stats.paragraphs).to eq(["Nothing yet."])
  end
end
