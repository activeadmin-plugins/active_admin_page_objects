# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::ActionItems do
  let(:index) { Pages::CustomerIndex.new }
  let(:show) { Pages::CustomerShow.new }

  describe "on an index page" do
    before { index.load }

    it "lists the labels" do
      expect(index.action_items.labels).to eq(["New Customer", "Report"])
    end

    it "checks for an item, ignoring case" do
      expect(index.action_items).to have_item("new customer")
      expect(index.action_items).to have_no_item("Delete Customer")
    end

    it "clicks an item" do
      index.action_items.click("New Customer")
      expect(Pages::CustomerForm.new).to have_page_title(text: "New Customer")
    end
  end

  shared_examples "action item dropdown" do
    before { show.load(id: create_customer.id) }

    it "lists the dropdown button among the items" do
      expect(show.action_items.labels).to eq(["Edit Customer", "Delete Customer", "More"])
    end

    it "reads the items of a closed dropdown" do
      dropdown = show.action_items.dropdown("more")
      expect(dropdown).to be_a(ActiveAdminPageObjects::DropdownMenu)
      expect(dropdown.label).to eq("More")
      expect(dropdown.labels).to eq(%w[Report Customers])
      expect(dropdown).to have_item("report")
      expect(dropdown).to have_no_item("Export")
      expect(show.action_items.dropdown.labels).to eq(%w[Report Customers])
    end

    it "opens the dropdown and clicks an item" do
      show.action_items.dropdown("More").click("Customers")
      expect(page).to have_current_path("/admin/customers")
    end

    it "clicks an item of an open dropdown" do
      dropdown = show.action_items.dropdown("More")
      dropdown.open
      dropdown.open
      dropdown.click("report")
      expect(index.flashes).to have_flash(:alert, "Report is not ready")
    end
  end

  it_behaves_like "action item dropdown"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "action item dropdown"

    it "raises for a missing dropdown or item" do
      show.load(id: create_customer.id)
      expect { show.action_items.dropdown("Nope") }.to raise_error(Capybara::ElementNotFound, /Nope/)
      expect { show.action_items.dropdown("More").click("Nope") }.to raise_error(Capybara::ElementNotFound, /Nope/)
    end
  end
end
