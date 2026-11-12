# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Tabs do
  it "raises because ActiveAdmin 4 removed the tabs component" do
    show = Pages::CustomerShow.new
    show.load(id: create_customer.id)
    expect { show.tabs }.to raise_error(ActiveAdminPageObjects::RemovedInActiveAdmin4, /tabs was removed/)
  end
end
