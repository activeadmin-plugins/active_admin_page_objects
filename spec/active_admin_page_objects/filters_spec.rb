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
      expect(typed.filter(:category)).to be_an_instance_of(ActiveAdminPageObjects::BooleanFilter)
      expect(filters.filter(:name)).to be_an_instance_of(ActiveAdminPageObjects::StringFilter)
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
      expect { mistyped.filter(:email) }.to raise_error(Capybara::ExpectationNotMet, /NumericFilter/)
      expect do
        mistyped.filter(:balance)
      end.to raise_error(Capybara::ExpectationNotMet, /PredicateFilter, but the page has .*NumericFilter/)
      expect(mistyped).to have_declared_filters
    end

    it "takes any key without declarations" do
      lenient = described_class.new(index, filters.root_element)
      expect(lenient.filter(:external_id)).to be_a(ActiveAdminPageObjects::StringFilter)
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

    it "declares a name that is a method of the section and reaches it with filter" do
      index.load
      named = Class.new(described_class) { filter :name, "Name", ActiveAdminPageObjects::StringFilter }
      expect(named.new(index, filters.root_element).filter(:name)).to be_an_instance_of(ActiveAdminPageObjects::StringFilter)
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) do
        filter :status, "Status", ActiveAdminPageObjects::SelectFilter
        filter :email, "E-mail", ActiveAdminPageObjects::StringFilter
      end
      expect(subclass.declarations.keys).to eq(%w[email external_id status])
      expect(subclass.declarations["email"])
        .to eq(label: "E-mail", type: ActiveAdminPageObjects::StringFilter, kind: :filter)
      expect(strict_class.declarations.keys).to eq(%w[email external_id])
      expect(strict_class.declarations["email"][:label]).to eq("Email")
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

  it "has no type registry" do
    expect(described_class).not_to respond_to(:register_type)
    expect(described_class).not_to respond_to(:types)
    expect { described_class::FILTER_CLASSES }.to raise_error(NameError, /private constant/)
  end

  it "returns a Filter for a wrapper class the gem has no class for" do
    index.load
    page.execute_script("document.querySelector('#q_created_at_input').className = 'date_time_picker input filter_form_field'")
    expect(described_class.new(index, filters.root_element).filter(:created_at))
      .to be_an_instance_of(ActiveAdminPageObjects::Filter)
  end

  describe "hidden filters" do
    let(:string_filter) { ActiveAdminPageObjects::StringFilter }

    before do
      index.load
      hide("#q_email_input")
    end

    it "leaves a hidden filter out by default" do
      Capybara.using_wait_time(0) do
        expect { filters.filter(:email) }.to raise_error(Capybara::ElementNotFound)
        expect(filters.has_exact_filters?).to be(false)
        expect(filters.has_declared_filters?).to be(false)
      end
      expect(filters.exact_mismatches).to eq(missing: ["email"], unexpected: [], labels: {})
      expect(filters.declared_label_mismatches).to eq("email" => nil)
      expect(filters).to have_exact_filters(except: :email)

      klass = string_filter
      partial = declared_filters { filter :name, "Name", klass }
      expect(partial.exact_mismatches[:unexpected]).to include("external_id")
      expect(partial.exact_mismatches[:unexpected]).not_to include("email")
    end

    it "takes a hidden filter when the query has visible: :all" do
      expect(filters.filter(:email, visible: :all)).to be_an_instance_of(string_filter)
      expect(filters).to have_exact_filters(visible: :all)
      expect(filters).to have_declared_filters(visible: :all)
      expect(filters).to have_no_declared_filters(visible: :visible)
      expect(filters.exact_mismatches(visible: :all)).to eq(missing: [], unexpected: [], labels: {})

      klass = string_filter
      partial = declared_filters { filter :name, "Name", klass }
      expect(partial.exact_mismatches(visible: :all)[:unexpected]).to include("email")
    end

    it "takes a hidden filter declared with visible: :all" do
      klass = string_filter
      declared = declared_filters do
        filter :name, "Name", klass
        filter :email, "Email", klass, visible: :all
      end
      expect(declared.class.declarations["email"]).to eq(label: "Email", type: klass, kind: :filter, visible: :all)
      expect(declared.filter(:email)).to be_an_instance_of(klass)
      expect(declared).to have_declared_filters
      expect(declared).to have_exact_filters(only: %i[name email])
      expect(declared.exact_mismatches).to include(missing: [], labels: {})
      Capybara.using_wait_time(0) do
        expect { declared.filter(:email, visible: :visible) }.to raise_error(Capybara::ElementNotFound)
      end
      expect(declared.declared_label_mismatches(visible: :visible)).to eq("email" => nil)
    end
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

  describe "a hidden native select" do
    # The section class of a select widget: it reads the select the widget hides.
    def reading_hidden_select(base)
      Class.new(base) do
        private

        def native_select_visibility = :all
      end
    end

    before { index.load }

    # +hiding+ is the spec helper that takes the select away.
    shared_examples "a select that is not found" do |hiding|
      it "is not found by a SelectFilter" do
        status = filters.filter(:status)
        expect(status).to have_selected("Any")
        send(hiding, "#q_status")
        Capybara.using_wait_time(0) do
          expect { status.select_option("pending") }.to raise_error(Capybara::ElementNotFound)
          %i[has_selected? has_no_selected? has_option? has_no_option? has_item? has_no_item?].each do |query|
            expect { status.public_send(query, "Any") }.to raise_error(Capybara::ElementNotFound)
          end
          expect { status.has_disabled? }.to raise_error(Capybara::ElementNotFound)
          expect { status.has_no_disabled? }.to raise_error(Capybara::ElementNotFound)
        end
        expect(page).to have_select("q_status", selected: "Any", visible: :all)
      end

      it "is not found by a BooleanFilter" do
        active = filters.filter(:active)
        send(hiding, "#q_active")
        Capybara.using_wait_time(0) do
          expect { active.set(true) }.to raise_error(Capybara::ElementNotFound)
          %i[has_value? has_no_value?].each do |query|
            expect { active.public_send(query, true) }.to raise_error(Capybara::ElementNotFound)
          end
        end
      end

      it "is not found as the predicate select of a StringFilter or a NumericFilter" do
        %i[name balance].each do |key|
          filter = filters.filter(key)
          send(hiding, "#q_#{key}_input select")
          Capybara.using_wait_time(0) do
            expect { filter.fill_in(with: "5", predicate: :eq) }.to raise_error(Capybara::ElementNotFound)
            expect { filter.has_value?("", predicate: "Equals") }.to raise_error(Capybara::ElementNotFound)
            expect { filter.has_no_value?("5", predicate: "Equals") }.to raise_error(Capybara::ElementNotFound)
          end
          expect(filter.predicate).to be_nil
          filter.fill_in(with: "5")
          expect(filter).to have_value("5")
        end
      end

      it "is read by a filter class that overrides native_select_visibility" do
        select_class = reading_hidden_select(ActiveAdminPageObjects::SelectFilter)
        boolean_class = reading_hidden_select(ActiveAdminPageObjects::BooleanFilter)
        string_class = reading_hidden_select(ActiveAdminPageObjects::StringFilter)
        declared = declared_filters do
          filter :name, "Name", string_class
          filter :status, "Status", select_class
          filter :active, "Active", boolean_class
        end
        send(hiding, "#q_status, #q_active, #q_name_input select")

        status = declared.filter(:status)
        expect(status).to have_selected("Any")
        expect(status).to have_option("pending")
        expect(status).to have_no_option("archived")
        expect(status).to have_no_disabled
        status.select_option("pending")
        expect(status).to have_item("pending")
        expect(status).to have_no_selected("Any")

        active = declared.filter(:active)
        expect(active).to have_value(nil)
        active.set(false)
        expect(active).to have_value(false)

        name = declared.filter(:name)
        expect(name.predicate).to eq("Contains")
        name.fill_in(with: "Beta", predicate: :eq)
        expect(name).to have_value("Beta", predicate: "Equals")

        filters.submit
        expect(names).to eq(["Beta"])
      end
    end

    context "when CSS hides it" do
      it_behaves_like "a select that is not found", :hide
    end

    context "when it is marked aria-hidden and CSS leaves it visible" do
      it_behaves_like "a select that is not found", :aria_hide
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
