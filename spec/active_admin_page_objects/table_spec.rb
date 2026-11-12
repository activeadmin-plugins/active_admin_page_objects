# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Table do
  let(:index) { Pages::CustomerIndex.new }
  let(:table) { index.table }
  let!(:customers) { create_customers(3, category: create_category) }

  shared_examples "index table" do
    before { index.load }

    it "reads the headers and column keys" do
      expect(table.header_names.map(&:downcase)).to eq(%w[id name email status balance active category created])
      expect(table.column_keys).to eq(%w[id name email status balance active category created])
    end

    it "compares headers ignoring case, with or without defaults" do
      expect(table).to have_header_names
      expect(table).to have_header_names("ID", "NAME", "EMAIL", "STATUS", "BALANCE", "ACTIVE", "CATEGORY", "CREATED")
      expect(table).to have_no_header_names("Id", "Name")
    end

    it "counts rows" do
      expect(table).to have_rows(count: 3)
      expect(table).to have_rows
      expect(table).to have_no_rows(count: 2)
      expect(table.rows.size).to eq(3)
    end

    it "finds a row by record id and reads its cells" do
      customer = customers.first
      row = table.row(customer.id)
      expect(row.record_id).to eq(customer.id.to_s)
      expect(row).to have_cell(:name, exact_text: customer.name)
      expect(row).to have_cell("CATEGORY", exact_text: "Retail")
      expect(row).to have_no_cell(:name, exact_text: "Nobody")
      expect(row).to have_no_cell(:secret)
      expect(row.cell(:email)).to have_text(customer.email)
    end

    it "keeps rows in table order" do
      expect(table.rows.map(&:record_id)).to eq(customers.reverse.map { |c| c.id.to_s })
    end
  end

  it_behaves_like "index table"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "index table"
  end

  it "ticks a row's batch checkbox" do
    index.load
    row = table.row(customers.first.id)
    row.select
    expect(row.cell(:id).find(:xpath, "..")).to have_checked_field(type: "checkbox")
  end

  it "raises without header names to compare" do
    index.load
    expect { ActiveAdminPageObjects::Table.new(index, table.root_element).has_header_names? }
      .to raise_error(ArgumentError, /default_header_names/)
  end

  it "is absent on a blank slate" do
    tags = Pages::TagIndex.new
    tags.load
    expect(tags).to have_blank_slate(text: "There are no Tags yet.")
    expect(tags).to have_no_table
    index.load
    expect(index).to have_no_blank_slate
  end
end
