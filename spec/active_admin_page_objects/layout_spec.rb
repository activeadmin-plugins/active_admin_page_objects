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

  context "with rack_test", driver: :rack_test do
    it "exposes the same elements" do
      expect(dashboard).to have_site_title(text: "Page Objects Dummy")
      expect(dashboard).to have_page_title(text: "Dashboard")
      expect(dashboard.welcome.title).to eq("Welcome")
    end
  end
end
