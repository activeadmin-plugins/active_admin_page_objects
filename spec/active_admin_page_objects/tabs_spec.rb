# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Tabs do
  let(:show) { Pages::CustomerShow.new }
  let(:customer) { create_customer }

  before do
    Order.create!(customer: customer, reference: "REF-1", state: "paid", quantity: 2)
    show.load(id: customer.id)
  end

  it "lists the tabs and reads the open one" do
    expect(show.tabs.labels).to eq(%w[Overview Orders])
    expect(show.tabs).to have_tab("orders")
    expect(show.tabs).to have_no_tab("Missing")
    expect(show.tabs.current).to eq("Overview")
    expect(show.tabs.body).to have_text("Overview body")
    expect(show.tabs.body).to have_no_text("REF-1")
  end

  it "switches to another tab" do
    show.tabs.switch("Orders")
    expect(show.tabs.current).to eq("Orders")
    expect(show.tabs.body).to have_text("REF-1")
    expect(show.tabs.body).to have_no_text("Overview body")
  end

  it "raises for a missing tab" do
    expect { show.tabs.switch("Missing") }.to raise_error(Capybara::ElementNotFound, /Missing/)
  end

  it "does not take the main menu for tabs" do
    dashboard = Pages::Dashboard.new
    dashboard.load
    expect(dashboard).to have_no_css(ActiveAdminPageObjects.selector(:tabs))
  end

  context "with rack_test", driver: :rack_test do
    it "lists the tabs without an open one" do
      expect(show.tabs.labels).to eq(%w[Overview Orders])
      expect(show.tabs.current).to be_nil
      expect(show.tabs.body).to have_text("Overview body")
    end
  end
end
