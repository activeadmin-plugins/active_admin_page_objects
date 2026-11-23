# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::MainMenu do
  let(:dashboard) { Pages::Dashboard.new }

  shared_examples "menu navigation" do
    before { dashboard.load }

    it "goes to a top-level item" do
      dashboard.main_menu.go("Customers")
      expect(page).to have_current_path("/admin/customers")
      expect(dashboard.main_menu.current_labels).to eq(["Customers"])
    end

    it "goes to a nested item in a closed submenu" do
      dashboard.main_menu.go("catalog", "Orders")
      expect(page).to have_current_path("/admin/orders")
      expect(dashboard.main_menu.current_labels).to eq(%w[Catalog Orders])
    end

    it "checks for items" do
      expect(dashboard.main_menu).to have_item("Catalog", "Categories")
      expect(dashboard.main_menu).to have_item("Tags")
      expect(dashboard.main_menu).to have_no_item("Catalog", "Tags")
      expect(dashboard.main_menu).to have_no_item("Reports")
    end

    it "lists item labels" do
      expect(dashboard.main_menu.labels).to eq(%w[Dashboard Customers Tags Catalog])
      expect(dashboard.main_menu.labels("catalog")).to eq(%w[Categories Orders])
      expect { dashboard.main_menu.labels("Nope") }.to raise_error(Capybara::ElementNotFound)
    end

    it "reports the current item" do
      expect(dashboard.main_menu.current_labels).to eq(["Dashboard"])
    end

    it "refuses an item without a link" do
      expect { dashboard.main_menu.go("Catalog") }.to raise_error(ArgumentError, /no link/)
    end

    it "raises for a missing item" do
      expect { dashboard.main_menu.go("Nope") }.to raise_error(Capybara::ElementNotFound)
    end
  end

  it_behaves_like "menu navigation"

  context "when clicking" do
    before { dashboard.load }

    it "hovers the parent and clicks a nested item" do
      dashboard.main_menu.click("catalog", "Orders")
      expect(page).to have_current_path("/admin/orders")
      expect(dashboard.main_menu.current_labels).to eq(%w[Catalog Orders])
    end

    it "clicks a top-level item" do
      dashboard.main_menu.click("Customers")
      expect(page).to have_current_path("/admin/customers")
    end

    it "raises for a missing item" do
      expect { dashboard.main_menu.click("Catalog", "Nope") }.to raise_error(Capybara::ElementNotFound)
      expect { dashboard.main_menu.click }.to raise_error(ArgumentError)
    end

    it "raises for a hidden submenu item" do
      hide("#tabs li li")
      expect { dashboard.main_menu.click("Catalog", "Orders") }.to raise_error(Capybara::ElementNotFound)
      expect(page).to have_current_path("/admin/dashboard")
    end

    it "raises for a hidden top-level item" do
      hide("#tabs > li")
      expect { dashboard.main_menu.click("Customers") }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context "with rack_test", driver: :rack_test do
    it_behaves_like "menu navigation"

    it "clicks a top-level item without hovering" do
      dashboard.load
      dashboard.main_menu.click("Customers")
      expect(page).to have_current_path("/admin/customers")
    end
  end
end
