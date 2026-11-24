# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Layout do
  let(:dashboard) { Pages::Dashboard.new }

  before { dashboard.load }

  it "exposes the header elements" do
    expect(dashboard).to have_site_title(text: "Page Objects Dummy")
    expect(dashboard).to have_dark_mode_toggle
    expect(dashboard).to have_theme_switcher
    expect(dashboard).to have_user_menu_button
    expect(dashboard).to have_page_title(text: "Dashboard")
    expect(dashboard).to have_main_menu
    expect(dashboard).to have_no_action_items
    expect(dashboard).to have_no_flashes
    expect(dashboard).to have_no_blank_slate
  end

  it "finds a panel by title, ignoring case" do
    panel = dashboard.panel("stats")
    expect(panel.title).to eq("Stats")
    expect(panel.body).to have_text("Nothing yet.")
  end

  it "raises for the utility navigation removed in ActiveAdmin 4" do
    expect { dashboard.utility_navigation }.to raise_error(ActiveAdminPageObjects::RemovedInActiveAdmin4, /utility navigation/)
  end

  describe ".add_element" do
    after { described_class.elements.delete(:heading_note) }

    it "declares the element on pages defined before and after the call" do
      described_class.add_element(:heading_note, "[data-test-page-header] h2")
      later = Class.new(SitePrism::Page) { include ActiveAdminPageObjects::Layout }.new

      expect(described_class.elements[:heading_note]).to eq(["[data-test-page-header] h2"])
      expect(dashboard.heading_note.text).to eq("Dashboard")
      expect(dashboard).to have_heading_note
      expect(later).to have_heading_note
    end

    it "replaces an element that is added again" do
      described_class.add_element(:heading_note, "#no_such_heading")
      expect(dashboard).to have_no_heading_note
      described_class.add_element(:heading_note, :active_admin, :site_title)
      expect(dashboard.heading_note.text).to eq("Page Objects Dummy")
    end
  end

  context "with rack_test", driver: :rack_test do
    it "exposes the same elements" do
      expect(dashboard).to have_site_title(text: "Page Objects Dummy")
      expect(dashboard).to have_page_title(text: "Dashboard")
      expect(dashboard.welcome.title).to eq("Welcome")
    end
  end
end
