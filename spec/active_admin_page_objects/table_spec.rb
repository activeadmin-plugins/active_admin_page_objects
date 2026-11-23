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

    it "has the declared column labels and no other column" do
      expect(table).to have_declared_columns(except: :notes)
      expect(table).to have_exact_columns(except: :notes)
      expect(table).to have_no_exact_columns
      expect(table.declared_label_mismatches).to eq("notes" => nil)
      expect(table.exact_mismatches).to eq(missing: ["notes"], unexpected: [], labels: {})
    end

    it "has an optional column when the page shows it" do
      index.load(query: { with_notes: 1 })
      expect(table).to have_exact_columns
      expect(table).to have_exact_columns(except: :notes)
      expect(table.exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "reports the columns that are missing, not declared or labelled otherwise" do
      partial = declared_table do
        column :id, "ID"
        column :name, "Name"
        column :secret, "Secret"
      end
      expect(partial).to have_no_exact_columns
      expect(partial.has_exact_columns?(wait: 0)).to be(false)
      expect(partial.exact_mismatches).to eq(
        missing: ["secret"],
        unexpected: %w[selectable email external_id status balance active category created actions],
        labels: { "id" => "Id" }
      )
      expect(partial).to have_exact_columns(only: :name)
      expect(partial).to have_no_exact_columns(only: %i[name secret])
      expect(partial.exact_mismatches(except: %i[id secret])).to include(missing: [], labels: {})
      expect(partial.exact_mismatches(except: :name)[:unexpected]).not_to include("name")
      expect { partial.has_exact_columns?(only: :email) }.to raise_error(ArgumentError, /:email is not declared/)
      expect { partial.has_declared_columns?(except: :email) }.to raise_error(ArgumentError, /:email is not declared/)
    end

    it "keys the untitled selection and actions columns" do
      untitled = declared_table do
        column :selectable, "Select"
        column :actions, "Actions"
      end
      expect(untitled.declared_label_mismatches).to eq("selectable" => "", "actions" => "")
      expect(untitled.exact_mismatches[:missing]).to eq([])
      expect(declared_table { column :actions, "" }).to have_declared_columns
      index.load(query: { with_notes: 1 })
      expect(declared_table { column :actions, "" }).to have_declared_columns
      expect(table.exact_mismatches[:unexpected]).to eq([])
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
      expect { lenient.has_declared_columns? }.to raise_error(ArgumentError, /declares no labels/)
      expect { lenient.has_exact_columns? }.to raise_error(ArgumentError, /declares no labels/)
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

  describe "hidden columns" do
    let(:customer) { customers.first }

    before do
      index.load
      hide('[data-column="email"]')
    end

    it "leaves a hidden column out by default" do
      row = table.row(customer.id)
      Capybara.using_wait_time(0) do
        expect { row.cell(:email) }.to raise_error(Capybara::ElementNotFound)
        expect(row.has_cell?(:email)).to be(false)
        expect(table.has_exact_columns?(except: :notes)).to be(false)
        expect(table.has_declared_columns?(except: :notes)).to be(false)
      end
      expect(row).to have_no_cell(:email)
      expect(table.exact_mismatches(except: :notes)).to eq(missing: ["email"], unexpected: [], labels: {})
      expect(table).to have_exact_columns(except: %i[email notes])

      partial = declared_table { column :name, "Name" }
      expect(partial.exact_mismatches[:unexpected]).to include("status")
      expect(partial.exact_mismatches[:unexpected]).not_to include("email")
    end

    it "takes a hidden column when the query has visible: :all" do
      row = table.row(customer.id)
      expect(row.cell(:email, visible: :all).text(:all)).to eq(customer.email)
      expect(row).to have_cell(:email, visible: :all, exact_text: customer.email)
      expect(table).to have_exact_columns(except: :notes, visible: :all)
      expect(table).to have_declared_columns(except: :notes, visible: :all)
      expect(table).to have_no_exact_columns(except: :notes, visible: :visible)

      partial = declared_table { column :name, "Name" }
      expect(partial.exact_mismatches(visible: :all)[:unexpected]).to include("email")
    end

    it "takes a hidden column declared with visible: :all" do
      hide('[data-column="status"]')
      declared = declared_table do
        column :name, "Name"
        column :email, "Email", visible: :all
        column :status, "Status", visible: :all
      end
      expect(declared.class.declarations).to include("name" => { label: "Name" }, "email" => { label: "Email", visible: :all })
      row = declared.row(customer.id)
      expect(row.cell(:email).text(:all)).to eq(customer.email)
      expect(row).to have_cell(:email, exact_text: customer.email)
      expect(declared).to have_declared_columns
      expect(declared).to have_exact_columns(only: %i[name email])
      expect(declared.exact_mismatches).to include(missing: [], labels: {})
      Capybara.using_wait_time(0) do
        expect { row.cell(:email, visible: :visible) }.to raise_error(Capybara::ElementNotFound)
        expect(row.has_cell?(:email, visible: :visible)).to be(false)
      end
      expect(declared.declared_label_mismatches(visible: :visible)).to eq("email" => nil, "status" => nil)
    end

    it "leaves a hidden selection or actions column out by default" do
      hide("thead th:first-child, thead th:last-child")
      expect(table.exact_mismatches(except: %i[email notes])).to eq(missing: %w[selectable actions], unexpected: [], labels: {})
      expect(table).to have_exact_columns(except: :notes, visible: :all)

      partial = declared_table { column :name, "Name" }
      expect(partial.exact_mismatches[:unexpected]).not_to include("selectable", "actions")
      expect(partial.exact_mismatches(visible: :all)[:unexpected]).to include("selectable", "actions")
      expect(declared_table { column :actions, "", visible: :all }).to have_declared_columns
    end
  end

  describe "declared columns" do
    let(:strict_class) do
      Class.new(described_class) do
        column :id, "Id"
        column :name, "Name"
      end
    end

    it "rejects an undeclared key before it queries the page" do
      row = described_class::Row.new(strict_class.new(nil, nil), nil)
      message = /:secret is not declared; declared keys: id, name/
      expect { row.cell(:secret) }.to raise_error(ArgumentError, message)
      expect { row.has_cell?(:secret) }.to raise_error(ArgumentError, message)
      expect { row.has_no_cell?(:secret) }.to raise_error(ArgumentError, message)
      expect { row.cell("Secret") }.to raise_error(ArgumentError, /"Secret" is not declared/)
    end

    it "requires a label" do
      expect { Class.new(described_class) { column :actions } }.to raise_error(ArgumentError)
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
      expect(subclass.declarations["email"]).to eq(label: "Email")
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
