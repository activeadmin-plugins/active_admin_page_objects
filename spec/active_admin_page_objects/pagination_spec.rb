# frozen_string_literal: true

# The dummy app shows 5 customers per page.
RSpec.describe ActiveAdminPageObjects::Pagination do
  let(:index) { Pages::CustomerIndex.new }
  let(:pagination) { index.pagination }

  shared_examples "pagination" do
    before do
      create_customers(12)
      index.load
    end

    it "goes to a page by number" do
      expect(pagination.current_page).to eq(1)
      pagination.go_to(3)
      expect(pagination).to have_current_page(3)
      expect(pagination).to have_no_current_page(1)
      expect(index.table).to have_rows(count: 2)
    end

    it "steps forward and back" do
      pagination.next_page
      expect(pagination).to have_current_page(2)
      pagination.next_page
      expect(pagination).to have_current_page(3)
      pagination.previous_page
      expect(pagination).to have_current_page(2)
      expect(pagination.current_page).to eq(2)
    end
  end

  it_behaves_like "pagination"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "pagination"
  end

  it "is not rendered for a single page" do
    create_customers(2)
    index.load
    expect(index).to have_no_pagination
  end
end
