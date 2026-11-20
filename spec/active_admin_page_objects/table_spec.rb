# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Table do
  let(:index) { Pages::CustomerIndex.new }
  let(:table) { index.table }
  let!(:customers) { create_customers(3, category: create_category) }

  # A table over the index table's element, with the columns the block declares.
  def declared_table(&)
    Class.new(described_class, &).new(index, table.root_element)
  end

  shared_examples "index table" do
    before { index.load }

    it "reads the headers and column keys" do
      expect(table.header_names.map(&:downcase))
        .to eq(["id", "name", "email", "external id", "status", "balance", "active", "category", "created"])
      expect(table.column_keys).to eq(%w[id name email external_id status balance active category created])
    end

    it "compares headers ignoring case" do
      expect(table).to have_header_names("ID", "NAME", "EMAIL", "EXTERNAL ID", "STATUS", "BALANCE", "ACTIVE", "CATEGORY",
                                         "CREATED")
      expect(table).to have_no_header_names("Id", "Name")
    end

    it "has the declared column labels" do
      expect(table).to have_declared_columns
      expect(table.declared_label_mismatches).to eq({})
    end

    it "compares a declared label exactly" do
      wrong_case = declared_table do
        column :id, "Id"
        column :external_id, "External id"
        column :secret, "Secret"
      end
      expect(wrong_case).to have_no_declared_columns
      expect(wrong_case.has_declared_columns?(wait: 0)).to be(false)
      expect(wrong_case.declared_label_mismatches).to eq("external_id" => "External ID", "secret" => nil)
      expect(declared_table { column "External ID", "External ID" }).to have_declared_columns
    end

    it "takes any key without declarations" do
      lenient = described_class.new(index, table.root_element)
      expect(lenient.rows.first).to have_no_cell(:secret)
      Capybara.using_wait_time(0) { expect(lenient.has_sortable_column?(:secret)).to be(false) }
      expect { lenient.has_declared_columns? }.to raise_error(ArgumentError, /declares no labels/)
      expect { lenient.declared_label_mismatches }.to raise_error(ArgumentError, /declares no labels/)
    end

    it "counts rows" do
      expect(table).to have_rows(count: 3)
      expect(table).to have_rows
      expect(table).to have_no_rows(count: 2)
      expect(table).to have_rows(text: customers.first.name)
      expect(table).to have_no_rows(text: "No such customer")
      expect(table.rows.size).to eq(3)
    end

    it "finds a row by record id and reads its cells" do
      customer = customers.first
      row = table.row(customer.id)
      expect(row.record_id).to eq(customer.id.to_s)
      expect(row).to have_cell(:name, exact_text: customer.name)
      expect(row).to have_cell("CATEGORY", exact_text: "Retail")
      expect(row).to have_no_cell(:name, exact_text: "Nobody")
      expect(row.cell(:email)).to have_text(customer.email)
    end

    it "keeps rows in table order" do
      expect(table.rows.map(&:record_id)).to eq(customers.reverse.map { |c| c.id.to_s })
    end

    it "reads the sort order and the sortable columns" do
      expect(table.sorted_by).to eq(["id", :desc])
      expect(table).to have_sortable_column(:name)
      expect(table).to have_sortable_column("Created")
      Capybara.using_wait_time(0) { expect(table.has_sortable_column?(:category)).to be(false) }
    end

    it "sorts by clicking a header" do
      table.sort_by(:name)
      expect(page).to have_current_path(/order=name_desc/)
      expect(index.table.sorted_by).to eq(["name", :desc])
    end

    it "sorts in a given direction" do
      table.sort_by(:name, :asc)
      expect(page).to have_current_path(/order=name_asc/)
      expect(index.table.sorted_by).to eq(["name", :asc])
      expect(index.table.rows.map(&:record_id)).to eq(customers.map { |c| c.id.to_s })

      index.table.sort_by("Name", "desc")
      expect(index.table.sorted_by).to eq(["name", :desc])
      expect(index.table.rows.map(&:record_id)).to eq(customers.reverse.map { |c| c.id.to_s })

      index.table.sort_by(:name, :desc)
      expect(page).to have_current_path(/order=name_desc/)
    end

    it "rejects an unknown sort direction" do
      expect { table.sort_by(:name, :up) }.to raise_error(ArgumentError, /direction/)
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
    expect { table.has_header_names? }.to raise_error(ArgumentError, /no header names given/)
    expect { table.has_no_header_names? }.to raise_error(ArgumentError, /no header names given/)
  end

  describe "declared columns" do
    let(:strict_class) do
      Class.new(described_class) do
        column :id, "Id"
        column :name, "Name"
      end
    end

    it "rejects an undeclared key before it queries the page" do
      strict = strict_class.new(nil, nil)
      message = /:secret is not declared; declared keys: id, name/
      expect { strict.sort_by(:secret) }.to raise_error(ArgumentError, message)
      expect { strict.has_sortable_column?(:secret) }.to raise_error(ArgumentError, message)

      row = described_class::Row.new(strict, nil)
      expect { row.cell(:secret) }.to raise_error(ArgumentError, message)
      expect { row.has_cell?(:secret) }.to raise_error(ArgumentError, message)
      expect { row.has_no_cell?(:secret) }.to raise_error(ArgumentError, message)
      expect { row.status_tag("Secret") }.to raise_error(ArgumentError, /"Secret" is not declared/)
    end

    it "takes a declared key as a symbol, a string or a label" do
      index.load
      row = strict_class.new(index, table.root_element).row(customers.first.id)
      expect(row).to have_cell(:name, exact_text: customers.first.name)
      expect(row).to have_cell("name", exact_text: customers.first.name)
      expect(row).to have_cell("Name", exact_text: customers.first.name)
      expect { row.cell(:email) }.to raise_error(ArgumentError, /:email is not declared/)
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) { column :email, "Email" }
      expect(subclass.declarations.keys).to eq(%w[id name email])
      expect(subclass.declarations["email"]).to eq(label: "Email", type: nil)
      expect(strict_class.declarations.keys).to eq(%w[id name])
      expect(described_class.declarations).to be_empty
    end
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
