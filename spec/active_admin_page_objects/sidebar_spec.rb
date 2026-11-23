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

  shared_examples "sidebar links" do
    it "lists the links of the body with their href attributes" do
      index = Pages::CustomerIndex.new
      index.load

      expect(index.sidebar("Help").links).to eq(
        [
          { text: "Report", href: "/admin/customers/report" },
          { text: "Active customers", href: "/admin/customers?scope=active" },
          { text: "Top", href: "#" }
        ]
      )
    end
  end

  it_behaves_like "sidebar links"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "sidebar links"
  end

  it "is found by a regexp title" do
    show = Pages::DocumentShow.new
    show.load(id: create_document.id)
    expect(show.versions.title).to eq("Versions (2)")
    expect(show.versions.body).to have_text("Two versions.")
    expect(show.sidebar(/\AVersions \(\d+\)\z/).title).to eq("Versions (2)")
    expect(show).to have_no_selector(:active_admin_sidebar, "Versions")
    expect(show).to have_no_selector(:active_admin_sidebar, /Routes/)
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
    expect(summary.links).to eq([])
  end
end
