# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::AttributesTable do
  let(:show) { Pages::CustomerShow.new }
  let(:customer) { create_customer(name: "Acme", external_id: "X-1", category: create_category("Wholesale")) }

  # An attributes table over the show page's element, with the rows the block declares.
  def declared_table(&)
    Class.new(described_class, &).new(show, show.attributes_table.root_element)
  end

  shared_examples "attributes table" do
    before { show.load(id: customer.id) }

    it "checks rows by key" do
      expect(show.attributes_table).to have_row(:name, exact_text: "Acme")
      expect(show.attributes_table).to have_row("Signed up")
      expect(show.attributes_table).to have_no_row(:name, exact_text: "Other")
      expect(show.attributes_table).to have_row(:name, exact_text: "ACME")
      expect(show.attributes_table).to have_row(:category, text: "wholesale")
      expect(show.attributes_table).to have_no_row(:name, exact_text: "acm")
      expect(show.attributes_table.has_no_row?(:name, exact_text: "acme", wait: 0)).to be(false)
    end

    it "reads a row and its value" do
      expect(show.attributes_table.row(:category)).to have_link("Wholesale")
      expect(show.attributes_table.value(:email)).to eq(customer.email)
      expect(show.attributes_table.value(:external_id)).to eq("X-1")
    end

    it "has the declared row labels and no other row" do
      expect(show.attributes_table).to have_declared_rows
      expect(show.attributes_table).to have_exact_rows
      expect(show.attributes_table.declared_label_mismatches).to eq({})
      expect(show.attributes_table.exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "reports the rows that are missing, not declared or labelled otherwise" do
      partial = declared_table do
        row :name, "Name"
        row :external_id, "External id"
        row :notes, "Notes"
      end
      expect(partial).to have_no_exact_rows
      expect(partial.has_exact_rows?(wait: 0)).to be(false)
      expect(partial.exact_mismatches).to eq(
        missing: ["notes"], unexpected: %w[email status balance category signed_up], labels: { "external_id" => "External ID" }
      )
      expect(partial).to have_exact_rows(only: :name)
      expect(partial).to have_no_exact_rows(only: %i[name notes])
      expect(partial).to have_declared_rows(except: %i[external_id notes])
      expect(partial.exact_mismatches(except: :notes)).to include(missing: [], labels: { "external_id" => "External ID" })
      expect(partial.exact_mismatches(except: :name)[:unexpected]).not_to include("name")
      expect(show.attributes_table).to have_exact_rows(except: :status)
      expect { partial.has_exact_rows?(only: :email) }.to raise_error(ArgumentError, /:email is not declared/)
      expect { partial.has_declared_rows?(except: :email) }.to raise_error(ArgumentError, /:email is not declared/)
    end

    it "compares a declared label exactly" do
      wrong_case = declared_table do
        row :name, "Name"
        row :external_id, "External id"
        row :signed_up, "Signed Up"
        row :notes, "Notes"
      end
      expect(wrong_case).to have_no_declared_rows
      expect(wrong_case.has_declared_rows?(wait: 0)).to be(false)
      expect(wrong_case.declared_label_mismatches)
        .to eq("external_id" => "External ID", "signed_up" => "Signed up", "notes" => nil)
      expect(declared_table { row :external_id, "External ID" }).to have_declared_rows
    end

    it "takes any key without declarations" do
      lenient = described_class.new(show, show.attributes_table.root_element)
      expect(lenient).to have_no_row(:notes)
      expect { lenient.has_declared_rows? }.to raise_error(ArgumentError, /declares no labels/)
      expect { lenient.has_exact_rows? }.to raise_error(ArgumentError, /declares no labels/)
    end
  end

  it_behaves_like "attributes table"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "attributes table"
  end

  describe "hidden rows" do
    let(:table) { show.attributes_table }

    before do
      show.load(id: customer.id)
      hide('tr[data-row="email"]')
    end

    it "leaves a hidden row out by default" do
      Capybara.using_wait_time(0) do
        expect { table.row(:email) }.to raise_error(Capybara::ElementNotFound)
        expect { table.value(:email) }.to raise_error(Capybara::ElementNotFound)
        expect(table.has_row?(:email)).to be(false)
        expect(table.has_exact_rows?).to be(false)
        expect(table.has_declared_rows?).to be(false)
      end
      expect(table).to have_no_row(:email)
      expect(table.exact_mismatches).to eq(missing: ["email"], unexpected: [], labels: {})
      expect(table.declared_label_mismatches).to eq("email" => nil)
      expect(table).to have_exact_rows(except: :email)

      partial = declared_table { row :name, "Name" }
      expect(partial.exact_mismatches[:unexpected]).to include("status")
      expect(partial.exact_mismatches[:unexpected]).not_to include("email")
    end

    it "takes a hidden row when the query has visible: :all" do
      expect(table.row(:email, visible: :all)[:"data-row"]).to eq("email")
      expect(table.value(:email, visible: :all)).to eq(customer.email)
      expect(table).to have_row(:email, visible: :all, exact_text: customer.email)
      expect(table).to have_exact_rows(visible: :all)
      expect(table).to have_declared_rows(visible: :all)
      expect(table).to have_no_exact_rows(visible: :visible)
      expect(table.exact_mismatches(visible: :all)).to eq(missing: [], unexpected: [], labels: {})

      partial = declared_table { row :name, "Name" }
      expect(partial.exact_mismatches(visible: :all)[:unexpected]).to include("email")
    end

    it "takes a hidden row declared with visible: :all" do
      hide('tr[data-row="status"]')
      declared = declared_table do
        row :name, "Name"
        row :email, "Email", visible: :all
        row :status, "Status", visible: :all
      end
      expect(declared.class.declarations).to include("name" => { label: "Name" }, "email" => { label: "Email", visible: :all })
      expect(declared.row(:email)[:"data-row"]).to eq("email")
      expect(declared.value(:email)).to eq(customer.email)
      expect(declared.value(:status)).to eq("Active")
      expect(declared).to have_row(:email, exact_text: customer.email)
      expect(declared).to have_declared_rows
      expect(declared).to have_exact_rows(only: %i[name email])
      expect(declared.exact_mismatches).to include(missing: [], labels: {})
      Capybara.using_wait_time(0) do
        expect { declared.row(:email, visible: :visible) }.to raise_error(Capybara::ElementNotFound)
        expect(declared.has_row?(:email, visible: :visible)).to be(false)
      end
      expect(declared.declared_label_mismatches(visible: :visible)).to eq("email" => nil, "status" => nil)
    end
  end

  describe "declared rows" do
    let(:strict_class) do
      Class.new(described_class) do
        row :name, "Name"
        row :external_id, "External ID"
      end
    end

    it "rejects an undeclared key before it queries the page" do
      strict = strict_class.new(nil, nil)
      message = /:notes is not declared; declared keys: name, external_id/
      expect { strict.has_row?(:notes) }.to raise_error(ArgumentError, message)
      expect { strict.has_no_row?(:notes) }.to raise_error(ArgumentError, message)
      expect { strict.row(:notes) }.to raise_error(ArgumentError, message)
      expect { strict.value(:notes) }.to raise_error(ArgumentError, message)
    end

    # An empty scope compares nothing, so every matcher would pass on any page.
    it "rejects a scope that leaves no declared row" do
      strict = strict_class.new(nil, nil)
      message = /leave no declared name to compare/
      expect { strict.has_exact_rows?(only: []) }.to raise_error(ArgumentError, message)
      expect { strict.has_no_exact_rows?(only: []) }.to raise_error(ArgumentError, message)
      expect { strict.has_declared_rows?(except: %i[name external_id]) }.to raise_error(ArgumentError, message)
      expect { strict.declared_label_mismatches(only: []) }.to raise_error(ArgumentError, message)
    end

    it "requires a label" do
      expect { Class.new(described_class) { row :notes } }.to raise_error(ArgumentError)
    end

    it "takes a declared key as a symbol, a string or a label" do
      show.load(id: customer.id)
      strict = strict_class.new(show, show.attributes_table.root_element)
      expect(strict.value(:external_id)).to eq("X-1")
      expect(strict.value("external_id")).to eq("X-1")
      expect(strict.value("External ID")).to eq("X-1")
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) { row :email, "Email" }
      expect(subclass.declarations.keys).to eq(%w[name external_id email])
      expect(subclass.declarations["email"]).to eq(label: "Email")
      expect(subclass.new(nil, nil)).not_to respond_to(:email)
      expect(strict_class.declarations.keys).to eq(%w[name external_id])
      expect(described_class.declarations).to be_empty
    end
  end
end
