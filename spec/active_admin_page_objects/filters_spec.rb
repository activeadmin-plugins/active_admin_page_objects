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

    it "has the declared filter labels and no other filter" do
      expect(filters).to have_declared_filters
      expect(filters).to have_exact_filters
      expect(filters.declared_label_mismatches).to eq({})
      expect(filters.exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "compares a declared label exactly" do
      wrong_case = declared_filters do
        filter :email, "Email", ActiveAdminPageObjects::StringFilter
        filter :external_id, "External id", ActiveAdminPageObjects::StringFilter
        filter :created_at, "Created At", ActiveAdminPageObjects::DateRangeFilter
        filter :notes, "Notes", ActiveAdminPageObjects::StringFilter
      end
      expect(wrong_case).to have_no_declared_filters
      expect(wrong_case.has_declared_filters?(wait: 0)).to be(false)
      expect(wrong_case.declared_label_mismatches)
        .to eq("external_id" => "External ID", "created_at" => "Created at", "notes" => nil)
      expect(wrong_case).to have_declared_filters(only: :email)
      expect(wrong_case).to have_declared_filters(except: %i[external_id created_at notes])
      expect(wrong_case).to have_no_declared_filters(except: %i[external_id created_at])
      external_id = declared_filters { filter :external_id, "External ID", ActiveAdminPageObjects::StringFilter }
      expect(external_id).to have_declared_filters
    end

    it "reports the filters that are missing, not declared or labelled otherwise" do
      partial = declared_filters do
        filter :email, "E-mail", ActiveAdminPageObjects::StringFilter
        filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
        filter :notes, "Notes", ActiveAdminPageObjects::StringFilter
      end
      expect(partial).to have_no_exact_filters
      expect(partial.has_exact_filters?(wait: 0)).to be(false)
      expect(partial.exact_mismatches).to eq(
        missing: ["notes"], unexpected: %w[name external_id status category active created_at], labels: { "email" => "Email" }
      )
      expect(partial).to have_exact_filters(only: :balance)
      expect(partial).to have_no_exact_filters(only: %i[balance notes])
      expect(partial.exact_mismatches(except: %i[email notes])).to include(missing: [], labels: {})
      expect(partial.exact_mismatches(except: :email)[:unexpected]).not_to include("email")
      expect(filters).to have_exact_filters(except: :status)
      expect { filters.has_exact_filters?(only: :notes) }.to raise_error(ArgumentError, /:notes is not declared/)
      expect { filters.has_declared_filters?(except: :notes) }.to raise_error(ArgumentError, /:notes is not declared/)
    end

    it "builds the declared class" do
      select_class = Class.new(ActiveAdminPageObjects::SelectFilter)
      typed = declared_filters do
        filter :status, "Status", select_class
        filter :category, "Category", ActiveAdminPageObjects::BooleanFilter
      end
      expect(typed.filter(:status)).to be_an_instance_of(select_class)
      expect(typed.status).to be_an_instance_of(select_class)
      expect(typed.category).to be_an_instance_of(ActiveAdminPageObjects::BooleanFilter)
      expect(filters.customer_name).to be_an_instance_of(ActiveAdminPageObjects::StringFilter)
    end

    it "raises when the page has a filter of another class than the declared one" do
      mistyped = declared_filters do
        filter :email, "Email", ActiveAdminPageObjects::NumericFilter
        filter :balance, "Balance", ActiveAdminPageObjects::PredicateFilter
      end
      expect { mistyped.filter(:email) }.to raise_error(
        Capybara::ExpectationNotMet,
        ":email is declared as ActiveAdminPageObjects::NumericFilter, but the page has ActiveAdminPageObjects::StringFilter"
      )
      expect { mistyped.email }.to raise_error(Capybara::ExpectationNotMet, /NumericFilter/)
      expect { mistyped.balance }.to raise_error(Capybara::ExpectationNotMet, /PredicateFilter, but the page has .*NumericFilter/)
      expect(mistyped).to have_declared_filters
    end

    it "finds a filter by its attribute under another name" do
      renamed = declared_filters { filter :code, "External ID", ActiveAdminPageObjects::StringFilter, attribute: :external_id }
      expect(renamed.code).to be_an_instance_of(ActiveAdminPageObjects::StringFilter)
      expect(renamed.code.root_element[:id]).to eq("q_external_id_input")
      expect(renamed).to have_declared_filters
      expect(renamed.exact_mismatches[:unexpected]).not_to include("external_id")
      expect { renamed.filter(:external_id) }.to raise_error(ArgumentError, /:external_id is not declared/)
    end

    it "takes any key without declarations" do
      lenient = described_class.new(index, filters.root_element)
      expect(lenient.filter(:external_id)).to be_a(ActiveAdminPageObjects::StringFilter)
      expect(lenient).not_to respond_to(:external_id)
      expect { lenient.has_declared_filters? }.to raise_error(ArgumentError, /declares no labels/)
      expect { lenient.has_exact_filters? }.to raise_error(ArgumentError, /declares no labels/)
    end
  end

  it_behaves_like "declared filters"

  describe "declared filters" do
    let(:strict_class) do
      Class.new(described_class) do
        filter :email, "Email", ActiveAdminPageObjects::StringFilter
        filter :external_id, "External ID", ActiveAdminPageObjects::StringFilter
      end
    end

    it "rejects an undeclared name before it queries the page" do
      expect { strict_class.new(nil, nil).filter(:name) }
        .to raise_error(ArgumentError, /:name is not declared; declared keys: email, external_id/)
    end

    it "takes a declared name as a symbol, a string or a label" do
      index.load
      strict = strict_class.new(index, filters.root_element)
      expect(strict.filter(:external_id)).to be_a(ActiveAdminPageObjects::StringFilter)
      expect(strict.filter("external_id")).to be_a(ActiveAdminPageObjects::StringFilter)
      expect(strict.filter("External ID")).to be_a(ActiveAdminPageObjects::StringFilter)
    end

    it "leaves links a plugin appends to the label out of it" do
      index.load
      page.execute_script(<<~JS)
        document.querySelector("#q_created_at_input label").insertAdjacentHTML("beforeend", '<a href="#">Set range</a>')
      JS
      expect(filters.root_element).to have_link("Set range")
      expect(filters).to have_declared_filters(only: :created_at)
    end

    it "requires a label and a section class" do
      expect { Class.new(described_class) { filter :email } }.to raise_error(ArgumentError)
      expect { Class.new(described_class) { filter :email, "Email" } }.to raise_error(ArgumentError)
      expect { Class.new(described_class) { filter :email, "Email", "StringFilter" } }
        .to raise_error(ArgumentError, '`filter :email` needs a section class, got "StringFilter"')
    end

    it "raises when the name is a method of the section" do
      expect { Class.new(described_class) { filter :name, "Name", ActiveAdminPageObjects::StringFilter } }
        .to raise_error(ArgumentError, "`filter :name` clashes with SitePrism::Section#name; rename it and pass attribute: :name")
      expect { Class.new(described_class) { filter :clear, "Clear", ActiveAdminPageObjects::StringFilter } }
        .to raise_error(ArgumentError, /clashes with ActiveAdminPageObjects::Filters#clear/)
      expect { Class.new(described_class) { filter :sel, "Sel", ActiveAdminPageObjects::StringFilter } }
        .to raise_error(ArgumentError, /clashes with ActiveAdminPageObjects::Section#sel/)
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) do
        filter :status, "Status", ActiveAdminPageObjects::SelectFilter
        filter :email, "E-mail", ActiveAdminPageObjects::StringFilter
      end
      expect(subclass.declarations.keys).to eq(%w[email external_id status])
      expect(subclass.declarations["email"])
        .to eq(label: "E-mail", type: ActiveAdminPageObjects::StringFilter, attribute: "email", kind: :filter)
      expect(strict_class.declarations.keys).to eq(%w[email external_id])
      expect(strict_class.declarations["email"][:label]).to eq("Email")
      expect(strict_class.new(nil, nil)).not_to respond_to(:status)
      expect(described_class.declarations).to be_empty
    end
  end

  it "returns a typed section per filter" do
    index.load
    expect(filters.customer_name).to be_a(ActiveAdminPageObjects::StringFilter)
    expect(filters.filter(:balance)).to be_a(ActiveAdminPageObjects::NumericFilter)
    expect(filters.filter(:status)).to be_a(ActiveAdminPageObjects::SelectFilter)
    expect(filters.filter(:category)).to be_a(ActiveAdminPageObjects::SelectFilter)
    expect(filters.filter(:active)).to be_a(ActiveAdminPageObjects::BooleanFilter)
    expect(filters.filter(:created_at)).to be_a(ActiveAdminPageObjects::DateRangeFilter)
    # ActiveAdmin 3 uppercases sidebar labels in CSS and Chrome reports the uppercased text.
    expect(filters.customer_name.label).to match(/\Aname\z/i)
  end

  it "registers a section for another input class" do
    custom = Class.new(ActiveAdminPageObjects::Filter)
    described_class.register_type("date_range", custom)
    index.load
    expect(described_class.new(index, filters.root_element).filter(:created_at)).to be_a(custom)
  ensure
    described_class.register_type("date_range", ActiveAdminPageObjects::DateRangeFilter)
  end

  describe ActiveAdminPageObjects::StringFilter do
    it "fills in with a predicate label and submits" do
      index.load
      filters.customer_name.fill_in(with: "Alpha", predicate: "Equals")
      filters.submit
      expect(index.table).to have_rows(count: 1)
      expect(names).to eq(["Alpha"])
      expect(filters.customer_name).to have_value("Alpha", predicate: "Equals")
      expect(filters.customer_name).to have_value("Alpha", predicate: :eq)
      expect(filters.customer_name).to have_no_value("Alpha", predicate: "Contains")
      expect(filters.customer_name.predicate).to eq("Equals")
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
      expect { filters.customer_name.fill_in(with: "x", predicate: :gt) }.to raise_error(ArgumentError, /:gt/)
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
      filters.customer_name.fill_in(with: "Alpha", predicate: "Contains")
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
