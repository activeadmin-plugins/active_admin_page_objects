# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Sidebar do
  it "is found by title on the index page" do
    create_customer
    index = Pages::CustomerIndex.new
    index.load

    help = index.sidebar("help")
    expect(help.title).to eq("Help")
    expect(help.body).to have_text("Use the filters to narrow the list.")
    expect(index.sidebar("Filters").title).to eq("Filters")
  end

  it "is found by title on the show page" do
    customer = create_customer
    Order.create!(customer: customer, reference: "REF-1", state: "new", quantity: 1)
    Order.create!(customer: customer, reference: "REF-2", state: "paid", quantity: 2)
    show = Pages::CustomerShow.new
    show.load(id: customer.id)

    summary = show.sidebar("SUMMARY")
    expect(summary.title).to eq("Summary")
    expect(summary.body).to have_text("Orders: 2")
  end
end
