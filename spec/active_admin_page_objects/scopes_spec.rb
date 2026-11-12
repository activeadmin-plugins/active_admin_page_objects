# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Scopes do
  let(:index) { Pages::CustomerIndex.new }
  let(:scopes) { index.scopes }

  before do
    create_customers(2, active: true)
    create_customer(active: false)
  end

  shared_examples "scopes" do
    before { index.load }

    it "lists the labels without counts" do
      expect(scopes.labels).to eq(%w[All Active Inactive])
    end

    it "reads the counts" do
      expect(scopes.count("All")).to eq(3)
      expect(scopes.count("active")).to eq(2)
      expect(scopes.count("Inactive")).to eq(1)
    end

    it "selects a scope" do
      expect(scopes).to have_selected("All")
      scopes.select("Inactive")
      expect(scopes).to have_selected("inactive")
      expect(scopes).to have_no_selected("All")
      expect(index.table).to have_rows(count: 1)
    end

    it "raises for a missing scope" do
      expect { scopes.select("Archived") }.to raise_error(Capybara::ElementNotFound, /Archived/)
    end
  end

  it_behaves_like "scopes"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "scopes"
  end
end
