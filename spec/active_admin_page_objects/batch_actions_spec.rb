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
    expect(batch_actions).to have_action(:set_status)
    expect(batch_actions).to have_no_action("Export Selected")
    expect(batch_actions).to have_no_action(:export)
  end

  it "applies an action without confirmation to selected rows" do
    index.table.row(customers.first.id).select
    index.table.row(customers.last.id).select
    batch_actions.apply("Flag Selected")
    expect(index.flashes).to have_flash(:notice, "Flagged 2 customers")
  end

  # The button toggles the menu: a second click would close it.
  it "applies an action when the menu is already open" do
    batch_actions.select_all
    find(".batch_actions_selector a.dropdown_menu_button").click
    expect(page).to have_css(".batch_actions_selector .dropdown_menu_list_wrapper")
    batch_actions.apply("Flag Selected")
    expect(index.flashes).to have_flash(:notice, "Flagged 3 customers")
  end

  it "confirms the dialog of an action with a confirmation" do
    batch_actions.select_all
    batch_actions.apply("Archive Selected")
    expect(index.flashes).to have_flash(:notice, "Archived 3 customers")
    expect(index).to have_no_modal_dialog
  end

  it "applies an action by its name" do
    batch_actions.select_all
    batch_actions.apply(:archive)
    expect(index.flashes).to have_flash(:notice, "Archived 3 customers")
  end

  it "fills the dialog inputs of an action with a form" do
    batch_actions.select_all
    batch_actions.apply("Set Status Selected", status: "pending")
    expect(index.flashes).to have_flash(:notice, "Set pending on 3 customers")
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
