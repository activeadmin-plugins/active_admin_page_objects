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
