# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Panel do
  it "is declared by title on a page" do
    dashboard = Pages::Dashboard.new
    dashboard.load
    expect(dashboard).to have_welcome
    expect(dashboard.welcome.title).to eq("Welcome")
    expect(dashboard.welcome.body).to have_text("Hello from the dashboard.")
  end

  it "is found by title on a show page" do
    customer = create_customer(notes: "Pays late")
    show = Pages::CustomerShow.new
    show.load(id: customer.id)
    expect(show.notes.body).to have_text("Pays late")
    expect(show.panel("NOTES").title).to eq("Notes")
    expect(show).to have_no_selector(:active_admin_panel, "Missing")
  end

  it "leaves out sidebar sections and the comments panel" do
    show = Pages::CustomerShow.new
    show.load(id: create_customer.id)
    expect(show).to have_selector(:active_admin_sidebar, "Summary")
    expect(show).to have_css(".comments.panel", text: "Comments (0)")
    expect(show).to have_no_selector(:active_admin_panel, "Summary")
    expect(show).to have_no_selector(:active_admin_panel, "Comments (0)")
    expect(show).to have_selector(:active_admin_panel, count: 2)
  end
end
