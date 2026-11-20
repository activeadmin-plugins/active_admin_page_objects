# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::ModalDialog do
  let(:index) { Pages::CustomerIndex.new }
  let(:dialog) { index.modal_dialog }

  def open_batch_action(label)
    find("#collection_selection_toggle_all").check
    find(".batch_actions_selector a.dropdown_menu_button").click
    click_link label
  end

  before do
    create_customers(3)
    index.load
  end

  it "asks for input, fills it and confirms" do
    open_batch_action("Set Status Selected")

    expect(dialog.title).to eq("Are you sure you want to do this?")
    expect(dialog).to have_field("status")
    expect(dialog).to have_no_field("missing", wait: 0)
    dialog.fill("status", with: "pending")
    dialog.confirm

    expect(index.flashes).to have_flash(:notice, "Set pending on 3 customers")
  end

  it "closes on cancel without running the action" do
    open_batch_action("Set Status Selected")
    expect(dialog.title).to eq("Are you sure you want to do this?")
    dialog.cancel

    expect(index).to have_no_modal_dialog
    expect(index.flashes).to have_no_flash(:notice)
  end

  it "shows the custom confirmation of an action" do
    open_batch_action("Archive Selected")

    expect(dialog.title).to eq("Archive the selected customers?")
    expect(dialog).to have_no_field("status", wait: 0)
    dialog.confirm

    expect(index.flashes).to have_flash(:notice, "Archived 3 customers")
  end
end
