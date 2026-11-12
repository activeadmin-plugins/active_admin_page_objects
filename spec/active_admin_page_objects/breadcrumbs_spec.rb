# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Breadcrumbs do
  let(:show) { Pages::CustomerShow.new }
  let(:customer) { create_customer }

  before { show.load(id: customer.id) }

  it "lists the links and labels" do
    expect(show.breadcrumbs.links.size).to eq(2)
    expect(show.breadcrumbs.labels).to eq(%w[Admin Customers])
  end

  it "matches the exact label sequence, ignoring case" do
    expect(show.breadcrumbs).to have_labels("Admin", "customers")
    expect(show.breadcrumbs).to have_no_labels("Admin")
    expect(show.breadcrumbs).to have_no_labels("Customers", "Admin")
  end
end
