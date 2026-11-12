# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::AttributesTable do
  let(:show) { Pages::CustomerShow.new }
  let(:customer) { create_customer(name: "Acme", category: create_category("Wholesale")) }

  before { show.load(id: customer.id) }

  it "checks rows by key" do
    expect(show.attributes_table).to have_row(:name, exact_text: "Acme")
    expect(show.attributes_table).to have_row("Signed up")
    expect(show.attributes_table).to have_no_row(:name, exact_text: "Other")
    expect(show.attributes_table).to have_no_row(:notes)
  end

  it "reads a row and its value" do
    expect(show.attributes_table.row(:category)).to have_link("Wholesale")
    expect(show.attributes_table.value(:email)).to eq(customer.email)
  end
end
