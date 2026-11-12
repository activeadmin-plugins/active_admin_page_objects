# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::BatchActions do
  let(:index) { Pages::CustomerIndex.new }
  let(:batch_actions) { index.batch_actions }
  let!(:customers) { create_customers(3) }

  before { index.load }

  it "lists actions by label or name" do
    expect(batch_actions).to have_action("Flag Selected")
    expect(batch_actions).to have_action("delete selected")
    expect(batch_actions).to have_action(:archive)
    expect(batch_actions).to have_no_action("Export Selected")
    expect(batch_actions).to have_no_action(:export)
  end

  it "applies an action without confirmation to selected rows" do
    index.table.row(customers.first.id).select
    index.table.row(customers.last.id).select
    batch_actions.apply("Flag Selected")
    expect(index.flashes).to have_flash(:notice, "Flagged 2 customers")
  end

  it "applies an action after accepting its confirmation" do
    batch_actions.select_all
    batch_actions.apply(:archive)
    expect(index.flashes).to have_flash(:notice, "Archived 3 customers")
  end

  it "applies the default destroy action" do
    index.table.row(customers.first.id).select
    batch_actions.apply("Delete Selected")
    expect(index.flashes).to have_flash(:notice, "Successfully deleted 1 customer")
    expect(index.table).to have_rows(count: 2)
  end

  it "raises for a missing action" do
    batch_actions.select_all
    expect { batch_actions.apply("Export Selected") }.to raise_error(Capybara::ElementNotFound, /Export Selected/)
  end
end
