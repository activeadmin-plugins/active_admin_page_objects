# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::ActionItems do
  let(:index) { Pages::CustomerIndex.new }

  before { index.load }

  it "lists the labels" do
    expect(index.action_items.labels).to eq(["New Customer", "Report"])
  end

  it "checks for an item, ignoring case" do
    expect(index.action_items).to have_item("new customer")
    expect(index.action_items).to have_no_item("Delete Customer")
  end

  it "clicks an item" do
    index.action_items.click("New Customer")
    expect(Pages::CustomerForm.new).to have_page_title(text: "New Customer")
  end

  it "raises for the dropdown removed in ActiveAdmin 4" do
    expect { index.action_items.dropdown("More") }
      .to raise_error(ActiveAdminPageObjects::RemovedInActiveAdmin4, /action item dropdown/)
  end
end
