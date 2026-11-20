# frozen_string_literal: true

# Stands in for a theme that prepends into SelectControl; inert unless active.
unless defined?(ChooseOptionSpy)
  module ChooseOptionSpy
    class << self
      attr_accessor :active

      def chosen
        @chosen ||= []
      end
    end

    def choose_option(scope, label)
      ChooseOptionSpy.chosen << label if ChooseOptionSpy.active
      super
    end

    private :choose_option
  end

  ActiveAdminPageObjects::SelectControl.prepend(ChooseOptionSpy)
end

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

  describe "a theme or plugin" do
    around do |example|
      saved = ActiveAdminPageObjects::Selectors::MAP.dup
      example.run
    ensure
      ActiveAdminPageObjects::Selectors::MAP.replace(saved)
    end

    it "prepends into SelectControl to drive a select widget" do
      ChooseOptionSpy.active = true
      create_category("Retail")
      create_customer(status: "active")

      index = Pages::CustomerIndex.new
      index.load
      index.filters.filter(:status).select_option("pending")
      expect(ChooseOptionSpy.chosen).to eq(["pending"])

      form_page = Pages::CustomerForm.new
      form_page.load(action: "new")
      form_page.form.choose(:status, "closed")
      expect(ChooseOptionSpy.chosen).to eq(%w[pending closed])
      expect(form_page.form.input(:status)).to have_select(selected: "closed")
    ensure
      ChooseOptionSpy.active = false
      ChooseOptionSpy.chosen.clear
    end

    it "registers a selector for a key ActiveAdmin 3 lacks" do
      ActiveAdminPageObjects.register_selectors(dark_mode_toggle: "#site_title")
      dashboard = Pages::Dashboard.new
      dashboard.load
      expect(dashboard).to have_dark_mode_toggle
      expect(dashboard).to have_theme_switcher
    end

    it "adds a section to every class that includes Layout" do
      early_class = Class.new(SitePrism::Page) { include ActiveAdminPageObjects::Layout }
      ActiveAdminPageObjects::Layout.add_section(:welcome_panel, ActiveAdminPageObjects::Panel,
                                                 :active_admin_panel, "Welcome")
      ActiveAdminPageObjects::Layout.add_section(:welcome_panel, ActiveAdminPageObjects::Panel,
                                                 :active_admin_panel, "Welcome")

      dashboard = Pages::Dashboard.new
      dashboard.load
      expect(dashboard).to respond_to(:welcome_panel)
      expect(dashboard.welcome_panel.title).to match(/Welcome/)
      expect(early_class.new).to respond_to(:welcome_panel)
    end
  end
end
