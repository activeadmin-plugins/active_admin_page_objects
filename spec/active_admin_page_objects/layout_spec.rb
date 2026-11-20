# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Layout do
  let(:dashboard) { Pages::Dashboard.new }

  before { dashboard.load }

  it "exposes the header elements" do
    expect(dashboard).to have_site_title(text: "Page Objects Dummy")
    expect(dashboard).to have_page_title(text: "Dashboard")
    expect(dashboard).to have_main_menu
    expect(dashboard).to have_breadcrumbs
    expect(dashboard).to have_no_blank_slate
    expect(dashboard).to have_no_modal_dialog
  end

  # ActiveAdmin 3 renders both containers on every page.
  it "finds the empty action items and flashes" do
    expect(dashboard.action_items.labels).to eq([])
    expect(dashboard.action_items).to have_no_item("New Customer")
    expect(dashboard.flashes.messages).to eq([])
    expect(dashboard.flashes).to have_no_flash(:notice)
  end

  it "raises for the elements ActiveAdmin 3 lacks" do
    expect { dashboard.dark_mode_toggle }
      .to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3, /dark mode toggle is not in ActiveAdmin 3/)
    expect { dashboard.theme_switcher }
      .to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3, /dark mode toggle is not in ActiveAdmin 3/)
    expect { dashboard.user_menu_button }
      .to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3, /user menu button is not in ActiveAdmin 3/)
    expect { dashboard.has_dark_mode_toggle? }.to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3)
    expect { dashboard.has_no_user_menu_button? }.to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3)
  end

  it "finds a panel by title, ignoring case" do
    panel = dashboard.panel("stats")
    expect(panel.title).to eq("Stats")
    expect(panel.body).to have_text("Nothing yet.")
  end

  it "finds a sidebar section by title, ignoring case" do
    index = Pages::CustomerIndex.new
    index.load
    sidebar = index.sidebar("help")
    expect(sidebar).to be_a(ActiveAdminPageObjects::Sidebar)
    expect(sidebar.body).to have_text("Use the filters to narrow the list.")
    expect(index).to have_no_selector(:active_admin_sidebar, "Missing")
  end

  it "returns the utility navigation" do
    expect(dashboard.utility_navigation).to be_a(ActiveAdminPageObjects::UtilityNavigation)
    expect(dashboard.utility_navigation.current_user).to eq("admin@example.com")
  end

  context "with rack_test", driver: :rack_test do
    it "exposes the same elements" do
      expect(dashboard).to have_site_title(text: "Page Objects Dummy")
      expect(dashboard).to have_page_title(text: "Dashboard")
      expect(dashboard.welcome.title).to eq("Welcome")
      expect(dashboard.utility_navigation.labels).to eq(["admin@example.com", "Logout"])
    end
  end
end
