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

  context "with a count in a tab label" do
    let(:document) { Pages::DocumentShow.new }

    before { document.load(id: create_document.id) }

    it "finds the tab by a regexp" do
      expect(document.tabs.labels).to eq(["Details", "Files (3)"])
      expect(document.tabs).to have_tab(/\AFiles \(\d+\)\z/)
      expect(document.tabs).to have_tab("files (3)")
      expect(document.tabs).to have_no_tab("Files")
      expect(document.tabs).to have_no_tab(/\AFiles\z/)
      expect(document.tabs.has_tab?(/\AFiles\z/, wait: 0)).to be(false)
      expect(document.tabs.has_no_tab?(/Files/, wait: 0)).to be(false)
    end

    it "switches to the tab a regexp matches" do
      document.tabs.switch(/\AFiles/)
      expect(document.tabs.current).to eq("Files (3)")
      expect(document.tabs.body).to have_text("Three files.")
      expect { document.tabs.switch(/Missing/) }.to raise_error(Capybara::ElementNotFound, /Missing/)
      expect { document.tabs.switch("Files") }.to raise_error(Capybara::ElementNotFound)
    end
  end

  it "does not take the main menu for tabs" do
    dashboard = Pages::Dashboard.new
    dashboard.load
    expect(dashboard).to have_no_css(ActiveAdminPageObjects.selector(:tabs))
  end

  context "with rack_test", driver: :rack_test do
    it "finds a tab by a regexp" do
      documents = Pages::DocumentShow.new
      documents.load(id: create_document.id)
      expect(documents.tabs).to have_tab(/\AFiles \(\d+\)\z/)
      expect(documents.tabs).to have_no_tab(/\Afiles/)
      expect(documents.tabs).to have_tab(/\Afiles/i)
    end

    it "lists the tabs without an open one" do
      expect(show.tabs.labels).to eq(%w[Overview Orders])
      expect(show.tabs.current).to be_nil
      expect(show.tabs.body).to have_text("Overview body")
    end
  end
end
