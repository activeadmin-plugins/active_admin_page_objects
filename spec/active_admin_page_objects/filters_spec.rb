# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Filters do
  let(:index) { Pages::CustomerIndex.new }
  let(:filters) { index.filters }

  before do
    category = create_category
    create_customer(name: "Alpha", email: "alpha@example.com", balance: 5, status: "active", active: true,
                    category: category, created_at: Time.utc(2026, 1, 10))
    create_customer(name: "Beta", email: "beta@example.com", balance: 50, status: "pending", active: false,
                    created_at: Time.utc(2026, 3, 10))
    create_customer(name: "Alphabet", email: "abc@example.com", balance: 500, status: "closed", active: true,
                    created_at: Time.utc(2026, 5, 10))
  end

  def names
    index.table.rows.map { |row| row.cell(:name).text }
  end

  # A filter form over the page's element, with the filters the block declares.
  def declared_filters(&)
    Class.new(described_class, &).new(index, filters.root_element)
  end

  shared_examples "declared filters" do
    before { index.load }

    it "has the declared filter labels" do
      expect(filters).to have_declared_filters
      expect(filters.declared_label_mismatches).to eq({})
    end

    it "compares a declared label exactly" do
      wrong_case = declared_filters do
        filter :name, "Name"
        filter :external_id, "External id"
        filter :created_at, "Created At"
        filter :notes, "Notes"
      end
      expect(wrong_case).to have_no_declared_filters
      expect(wrong_case.has_declared_filters?(wait: 0)).to be(false)
      expect(wrong_case.declared_label_mismatches)
        .to eq("external_id" => "External ID", "created_at" => "Created at", "notes" => nil)
      expect(declared_filters { filter :external_id, "External ID" }).to have_declared_filters
    end

    it "raises when a filter is declared with another class" do
      mistyped = declared_filters do
        filter :name, "Name", ActiveAdminPageObjects::NumericFilter
        filter :balance, "Balance", ActiveAdminPageObjects::PredicateFilter
      end
      expect { mistyped.filter(:name) }.to raise_error(
        Capybara::ExpectationNotMet,
        ":name is declared as ActiveAdminPageObjects::NumericFilter, but the page has ActiveAdminPageObjects::StringFilter"
      )
      expect(mistyped.filter(:balance)).to be_a(ActiveAdminPageObjects::NumericFilter)
      expect(mistyped).to have_declared_filters
    end

    it "takes any key without declarations" do
      lenient = described_class.new(index, filters.root_element)
      expect(lenient.filter(:external_id)).to be_a(ActiveAdminPageObjects::StringFilter)
      expect { lenient.has_declared_filters? }.to raise_error(ArgumentError, /declares no labels/)
    end
  end

  it_behaves_like "declared filters"

  describe "declared filters" do
    let(:strict_class) do
      Class.new(described_class) do
        filter :name, "Name", ActiveAdminPageObjects::StringFilter
        filter :external_id, "External ID"
      end
    end

    it "rejects an undeclared key before it queries the page" do
      expect { strict_class.new(nil, nil).filter(:email) }
        .to raise_error(ArgumentError, /:email is not declared; declared keys: name, external_id/)
    end

    it "takes a declared key as a symbol, a string or a label" do
      index.load
      strict = strict_class.new(index, filters.root_element)
      expect(strict.filter(:external_id)).to be_a(ActiveAdminPageObjects::StringFilter)
      expect(strict.filter("external_id")).to be_a(ActiveAdminPageObjects::StringFilter)
      expect(strict.filter("External ID")).to be_a(ActiveAdminPageObjects::StringFilter)
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) { filter :email, "Email" }
      expect(subclass.declarations.keys).to eq(%w[name external_id email])
      expect(subclass.declarations["name"]).to eq(label: "Name", type: ActiveAdminPageObjects::StringFilter)
      expect(strict_class.declarations.keys).to eq(%w[name external_id])
      expect(described_class.declarations).to be_empty
    end
  end

  it "returns a typed section per filter" do
    index.load
    expect(filters.filter(:name)).to be_a(ActiveAdminPageObjects::StringFilter)
    expect(filters.filter(:balance)).to be_a(ActiveAdminPageObjects::NumericFilter)
    expect(filters.filter(:status)).to be_a(ActiveAdminPageObjects::SelectFilter)
    expect(filters.filter(:category)).to be_a(ActiveAdminPageObjects::SelectFilter)
    expect(filters.filter(:active)).to be_a(ActiveAdminPageObjects::BooleanFilter)
    expect(filters.filter(:created_at)).to be_a(ActiveAdminPageObjects::DateRangeFilter)
    # ActiveAdmin 3 uppercases sidebar labels in CSS and Chrome reports the uppercased text.
    expect(filters.filter(:name).label).to match(/\Aname\z/i)
  end

  it "registers a section for another input class" do
    custom = Class.new(ActiveAdminPageObjects::Filter)
    described_class.register_type("date_range", custom)
    index.load
    expect(filters.filter(:created_at)).to be_a(custom)
  ensure
    described_class.register_type("date_range", ActiveAdminPageObjects::DateRangeFilter)
  end

  describe ActiveAdminPageObjects::StringFilter do
    it "fills in with a predicate label and submits" do
      index.load
      filters.filter(:name).fill_in(with: "Alpha", predicate: "Equals")
      filters.submit
      expect(index.table).to have_rows(count: 1)
      expect(names).to eq(["Alpha"])
      expect(filters.filter(:name)).to have_value("Alpha", predicate: "Equals")
      expect(filters.filter(:name)).to have_value("Alpha", predicate: :eq)
      expect(filters.filter(:name)).to have_no_value("Alpha", predicate: "Contains")
      expect(filters.filter(:name).predicate).to eq("Equals")
    end

    it "takes a ransack predicate symbol" do
      index.load
      filters.filter(:email).fill_in(with: "b", predicate: :start)
      filters.submit
      expect(names).to eq(["Beta"])
    end

    it "keeps the current predicate when none is given" do
      index.load
      index.name_filter.fill_in(with: "Alpha")
      index.filters_footer.submit
      expect(names).to contain_exactly("Alpha", "Alphabet")
      expect(index.name_filter).to have_value("Alpha")
      expect(index.name_filter).to have_no_value("Beta")
    end

    it "raises for an unknown predicate symbol" do
      index.load
      expect { filters.filter(:name).fill_in(with: "x", predicate: :gt) }.to raise_error(ArgumentError, /:gt/)
    end
  end

  describe ActiveAdminPageObjects::NumericFilter do
    it "fills in with a predicate" do
      index.load
      filters.filter(:balance).fill_in(with: 40, predicate: "Greater than")
      filters.submit
      expect(names).to contain_exactly("Beta", "Alphabet")
      expect(filters.filter(:balance)).to have_value("40.0", predicate: :gt)
    end
  end

  describe ActiveAdminPageObjects::SelectFilter do
    it "selects an option and reads the selection" do
      index.load
      status = filters.filter(:status)
      expect(status).to have_option("pending")
      expect(status).to have_no_option("archived")
      expect(status).to have_selected("Any")
      status.select_option("pending")
      expect(status).to have_item("pending")
      filters.submit
      expect(names).to eq(["Beta"])
      expect(filters.filter(:status)).to have_selected("pending")
      expect(filters.filter(:status)).to have_no_selected("active")
      expect(filters.filter(:status)).to have_no_item("active")
    end

    it "filters by an association" do
      index.load
      filters.filter(:category).select_option("Retail")
      filters.submit
      expect(names).to eq(["Alpha"])
    end

    it "reports the enabled state of a plain select" do
      index.load
      expect(filters.filter(:status)).to have_no_disabled
      page.execute_script("document.getElementById('q_status').disabled = true")
      expect(filters.filter(:status)).to have_disabled
    end
  end

  describe ActiveAdminPageObjects::BooleanFilter do
    it "sets true, false and any" do
      index.load
      active = filters.filter(:active)
      expect(active).to have_value(nil)
      active.set(false)
      filters.submit
      expect(names).to eq(["Beta"])
      expect(filters.filter(:active)).to have_value(false)
      expect(filters.filter(:active)).to have_no_value(true)
      filters.filter(:active).set(nil)
      filters.submit
      expect(index.table).to have_rows(count: 3)
    end
  end

  describe ActiveAdminPageObjects::DateRangeFilter do
    it "sets a range from ISO strings and Date objects" do
      index.load
      filters.filter(:created_at).set("2026-02-01", Date.new(2026, 4, 1))
      filters.submit
      expect(names).to eq(["Beta"])
      expect(filters.filter(:created_at)).to have_range("2026-02-01", "2026-04-01")
      expect(filters.filter(:created_at)).to have_range(Date.new(2026, 2, 1), "2026-04-01")
      expect(filters.filter(:created_at)).to have_no_range("2026-02-01")
    end

    it "leaves an open end" do
      index.load
      filters.filter(:created_at).set("2026-02-01")
      filters.submit
      expect(names).to contain_exactly("Beta", "Alphabet")
      expect(filters.filter(:created_at)).to have_range("2026-02-01", nil)
    end
  end

  it "clears the filters" do
    index.load(query: { "q[name_eq]" => "Beta" })
    expect(index.table).to have_rows(count: 1)
    filters.clear
    expect(index.table).to have_rows(count: 3)
    expect(page).to have_no_current_path(/q%5B/)
  end

  it "clears with the footer section" do
    index.load(query: { "q[name_eq]" => "Beta" })
    index.filters_footer.clear
    expect(index.table).to have_rows(count: 3)
  end

  # "Clear Filters" is left out: ActiveAdmin 3 clears in JavaScript.
  context "with rack_test", driver: :rack_test do
    it_behaves_like "declared filters"

    it "fills in values, selects and sets ranges without JavaScript" do
      index.load
      filters.filter(:name).fill_in(with: "Alpha", predicate: "Contains")
      filters.filter(:status).select_option("active")
      filters.filter(:active).set(true)
      filters.filter(:created_at).set("2026-01-01", "2026-12-31")
      filters.submit
      expect(names).to eq(["Alpha"])
      expect(filters.filter(:status)).to have_selected("active")
      expect(filters.filter(:created_at)).to have_range("2026-01-01", "2026-12-31")
    end
  end
end
