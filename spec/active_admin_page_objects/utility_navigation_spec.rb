# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::UtilityNavigation do
  let(:index) { Pages::CustomerIndex.new }

  shared_examples "utility navigation" do
    before { index.load }

    it "reads the current user and the labels" do
      navigation = index.utility_navigation
      expect(navigation).to be_a(described_class)
      expect(navigation.current_user).to eq("admin@example.com")
      expect(navigation.labels).to eq(["admin@example.com", "Logout"])
    end

    it "clicks the logout link" do
      index.utility_navigation.logout
      expect(page).to have_current_path("/admin")
      expect(Pages::Dashboard.new).to have_page_title(text: "Dashboard")
    end
  end

  it_behaves_like "utility navigation"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "utility navigation"
  end
end
