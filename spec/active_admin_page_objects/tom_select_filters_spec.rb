# frozen_string_literal: true

# The dummy app turns the order filters into Tom Select controls.
RSpec.describe "Filters driven by Tom Select" do
  let(:index) { Pages::OrderIndex.new }
  let(:filters) { index.filters }

  before do
    zed = create_customer(name: "Zed")
    amy = create_customer(name: "Amy")
    Order.create!(reference: "ORD-1", state: "new", quantity: 2, customer: zed)
    Order.create!(reference: "ORD-2", state: "paid", quantity: 7, customer: amy)
    Order.create!(reference: "XYZ-3", state: "shipped", quantity: 9, customer: amy)
    index.load
  end

  def references
    index.table.rows.map { |row| row.cell(:reference).text }
  end

  it "picks a string predicate through Tom Select" do
    filters.filter(:reference).fill_in(with: "ORD-2", predicate: "Equals")
    filters.submit
    expect(references).to eq(["ORD-2"])
    expect(filters.filter(:reference)).to have_value("ORD-2", predicate: :eq)
  end

  it "picks a numeric predicate through Tom Select" do
    filters.filter(:quantity).fill_in(with: 5, predicate: :gt)
    filters.submit
    expect(references).to contain_exactly("ORD-2", "XYZ-3")
    expect(filters.filter(:quantity)).to have_value("5", predicate: "Greater than")
  end

  it "selects an option after a search" do
    customer = filters.filter(:customer)
    customer.select_option("Amy", search: "Am")
    expect(customer).to have_item("Amy")
    expect(customer).to have_no_item("Any")
    filters.submit
    expect(references).to contain_exactly("ORD-2", "XYZ-3")
    expect(filters.filter(:customer)).to have_selected("Amy")
    expect(filters.filter(:customer)).to have_no_selected("Zed")
  end

  it "opens the dropdown to check the offered options" do
    state = filters.filter(:state)
    state.open
    expect(state).to have_option("paid")
    expect(state).to have_no_option("lost")
    state.select_option("paid")
    expect(state).to have_selected("paid")
  end

  it "creates an option" do
    state = filters.filter(:state)
    state.create_option("lost")
    expect(state).to have_item("lost")
    filters.submit
    expect(index).to have_blank_slate(text: "No Orders found")
  end

  it "reads the placeholder and the disabled state" do
    customer = filters.filter(:customer)
    expect(customer.placeholder).to eq("Choose")
    expect(customer).to have_no_disabled
    page.execute_script("document.getElementById('q_customer_id').tomselect.disable()")
    expect(customer).to have_disabled
  end
end
