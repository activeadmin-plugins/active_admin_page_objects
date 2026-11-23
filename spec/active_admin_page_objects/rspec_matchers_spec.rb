# frozen_string_literal: true

require "active_admin_page_objects/rspec"

# Stands in for capybara_active_admin: matchers of the same names, written for Capybara's `page`.
module OtherLibraryMatchers
  def have_page_title(text, options = {})
    have_css("#page_title", text: text, **options)
  end

  def have_table(options = {})
    have_css("table.index_table", **options)
  end

  def have_semantic_errors(options = {})
    have_css("ul.errors > li", **options)
  end

  def have_status_tag(type, **options)
    have_css("span.status_tag.#{type}", **options)
  end

  def have_flash_message(text, options = {})
    satisfy("show the flash #{text}") { |actual| actual.has_css?(".flash", text: text, **options) }
  end
end

RSpec.describe ActiveAdminPageObjects::RSpec::Matchers do
  let(:index) { Pages::CustomerIndex.new }
  let!(:customer) { create_customer(status: "pending") }

  it "names every matcher of capybara_active_admin 1.0.0" do
    expect(described_class::NAMES.size).to eq(24)
    detailed = described_class::DECLARED_NAMES + described_class::ERROR_MATCHERS.keys
    expect(described_class.public_instance_methods - detailed).to match_array(described_class::NAMES)
  end

  it "names the declared and the exact matchers of the four sections, and the exact error matchers" do
    expect(described_class::DECLARED_NAMES.size).to eq(16)
    expect(described_class::DECLARED_NAMES - described_class.public_instance_methods).to be_empty
    predicates = [ActiveAdminPageObjects::AttributesTable, ActiveAdminPageObjects::Table, ActiveAdminPageObjects::Filters,
                  ActiveAdminPageObjects::Form].flat_map { |klass| klass.public_instance_methods.grep(/\Ahas_(no_)?(declared|exact)_/) }
    names = predicates.map { |name| name.to_s.sub("has_", "have_").chomp("?").to_sym }
    expect(names).to match_array(described_class::DECLARED_NAMES + described_class::ERROR_MATCHERS.keys)
    expect(described_class::ERROR_MATCHERS.keys - described_class.public_instance_methods).to be_empty
  end

  context "when included after the other library" do
    include OtherLibraryMatchers
    include ActiveAdminPageObjects::RSpec::Matchers

    before { index.load }

    it "asks a page object its predicate" do
      expect(index).to have_page_title(text: "Customers")
      expect(index).to have_table
      expect(index.table.row(customer.id)).to have_status_tag(:status, "Pending", type: "pending")
    end

    it "asks a page object its has_no predicate when negated" do
      row = index.table.row(customer.id)
      allow(row).to receive(:has_no_status_tag?).and_call_original
      expect(row).not_to have_status_tag(:status, "Active")
      expect(row).to have_received(:has_no_status_tag?).with(:status, "Active")
      tags = Pages::TagIndex.new
      tags.load
      expect(tags).not_to have_table
    end

    it "negates the predicate of a page object without a has_no predicate" do
      form_page = Pages::CustomerForm.new
      form_page.load(action: "new")
      form = form_page.form
      allow(form).to receive(:respond_to?).and_call_original
      allow(form).to receive(:respond_to?).with(:has_no_semantic_errors?).and_return(false)
      Capybara.using_wait_time(0) { expect(form).not_to have_semantic_errors }
    end

    it "uses the other library's matcher on a Capybara session" do
      expect(page).to have_page_title("Customers")
      expect(page).not_to have_page_title("Orders")
      expect(page).to have_table(count: 1)
      expect(page).to have_status_tag(:pending, text: /pending/i)
      expect(page).not_to have_status_tag(:active)
      expect(page).not_to have_flash_message("Saved", wait: 0)
    end

    it "uses the other library's matcher on a page object without the predicate" do
      expect(index).not_to respond_to(:has_flash_message?)
      expect(index).not_to have_flash_message("Saved", wait: 0)
      index.action_items.click("Report")
      expect(index).to have_flash_message("Report failed")
    end

    it "reports the failure of the matcher it used" do
      expect { expect(index).to have_page_title(text: "Orders", wait: 0) }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /has_page_title\?\(.*\)` to be truthy, got false/)
      expect { Capybara.using_wait_time(0) { expect(index).not_to have_table } }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /has_no_table\?` to be truthy, got false/)
      expect { expect(page).to have_page_title("Orders", wait: 0) }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected to find .*#page_title/)
      expect { expect(page).not_to have_page_title("Customers", wait: 0) }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected not to find .*#page_title/)
      expect(have_page_title(text: "Customers").description).to match(/\Ahave page title \{:?text(: |=>)"Customers"\}\z/)
    end
  end

  context "when no other library defines the matcher" do
    include ActiveAdminPageObjects::RSpec::Matchers

    before { index.load }

    it "is the predicate matcher for any object" do
      expect(index).to have_page_title(text: "Customers")
      expect(index.table.row(customer.id)).not_to have_status_tag(:status, "Active")
      expect { expect(page).to have_footer }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /to respond to `has_footer\?`/)
    end

    it "uses a matcher of the same name that Capybara or SitePrism defines" do
      expect(page).to have_table(count: 1)
      expect(page).not_to have_table("Orders", wait: 0)
      expect(index).to have_table
    end
  end

  describe "failure messages of the declared and the exact matchers" do
    include ActiveAdminPageObjects::RSpec::Matchers

    let(:show) { Pages::CustomerShow.new }
    let(:rows) { show.attributes_table }
    let(:partial_rows) do
      Class.new(ActiveAdminPageObjects::AttributesTable) do
        row :name, "Name"
        row :external_id, "External id"
        row :notes, "Notes"
      end.new(show, rows.root_element)
    end

    before { show.load(id: customer.id) }

    def fail_with(message)
      raise_error(RSpec::Expectations::ExpectationNotMetError, message)
    end

    it "lists the missing and the unexpected elements and the labels that differ" do
      expect { expect(partial_rows).to have_exact_rows(wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected exactly the declared rows, but:
          missing: notes
          unexpected: email, status, balance, category, signed_up
          label of external_id: expected "External id", got "External ID"
      MESSAGE
    end

    it "leaves the unexpected elements out of the declared matcher's message" do
      expect { expect(partial_rows).to have_declared_rows(wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected the declared rows, but:
          missing: notes
          label of external_id: expected "External id", got "External ID"
      MESSAGE
    end

    it "names the scope given with only, except and visible" do
      expect { expect(partial_rows).to have_exact_rows(only: %i[name notes], wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected exactly the declared rows (only: name, notes), but:
          missing: notes
      MESSAGE
      expect { expect(partial_rows).to have_exact_rows(except: :notes, wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected exactly the declared rows (except: notes), but:
          unexpected: email, status, balance, category, signed_up
          label of external_id: expected "External id", got "External ID"
      MESSAGE
      expect { expect(partial_rows).to have_declared_rows(only: :notes, visible: :all, wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected the declared rows (only: notes; visible: all), but:
          missing: notes
      MESSAGE
      expect(partial_rows).to have_exact_rows(only: :name)
      expect(partial_rows).to have_declared_rows(except: %i[external_id notes])
    end

    it "says that the page matches when a negated matcher fails" do
      exact = "expected the rows to differ from the declared ones, but they match exactly"
      expect { expect(rows).to have_no_exact_rows(wait: 0) }.to fail_with(exact)
      expect { expect(rows).not_to have_exact_rows(wait: 0) }.to fail_with(exact)
      expect { expect(rows).to have_no_declared_rows(only: :name, wait: 0) }
        .to fail_with("expected a declared row to be missing or to have another label (only: name), but every one matches")
      expect { expect(partial_rows).to have_no_exact_rows(only: :name, wait: 0) }
        .to fail_with("expected the rows to differ from the declared ones (only: name), but they match exactly")
      expect(partial_rows).to have_no_exact_rows
      expect(partial_rows).not_to have_declared_rows
    end

    it "asks the opposite predicate when negated" do
      allow(partial_rows).to receive(:has_no_exact_rows?).and_call_original
      allow(partial_rows).to receive(:has_exact_rows?).and_call_original
      expect(partial_rows).not_to have_exact_rows(only: :notes)
      expect(partial_rows).to have_received(:has_no_exact_rows?).with(only: :notes)
      expect { expect(partial_rows).not_to have_no_exact_rows(only: :notes, wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected exactly the declared rows (only: notes), but:
          missing: notes
      MESSAGE
      expect(partial_rows).to have_received(:has_exact_rows?).with(only: :notes, wait: 0)
    end

    it "reports the columns, the filters and the fields the same way" do
      index.load
      expect { expect(index.table).to have_exact_columns(wait: 0) }
        .to fail_with("expected exactly the declared columns, but:\n  missing: notes")
      filters = Class.new(ActiveAdminPageObjects::Filters) do
        filter :email, "E-mail", ActiveAdminPageObjects::StringFilter
      end.new(index, index.filters.root_element)
      expect { expect(filters).to have_declared_filters(wait: 0) }
        .to fail_with(%(expected the declared filters, but:\n  label of email: expected "E-mail", got "Email"))
      expect { expect(index.filters).to have_no_declared_filters(wait: 0) }
        .to fail_with("expected a declared filter to be missing or to have another label, but every one matches")

      form_page = Pages::CustomerForm.new
      form_page.load(action: "new")
      form = Class.new(ActiveAdminPageObjects::Form) do
        field :email, "Email", ActiveAdminPageObjects::Form::StringField
        field :secret, "Secret", ActiveAdminPageObjects::Form::StringField
        has_many :orders, "Order list"
      end.new(form_page, form_page.form.root_element)
      expect { expect(form).to have_exact_fields(only: %i[secret orders], wait: 0) }.to fail_with(<<~MESSAGE.chomp)
        expected exactly the declared fields (only: secret, orders), but:
          missing: secret
          label of orders: expected "Order list", got "Orders"
      MESSAGE
      expect(form_page.form).to have_exact_fields
    end

    it "keeps its own message in a compound expectation" do
      expect { expect(partial_rows).to have_exact_rows(only: :notes, wait: 0).and have_declared_rows(only: :name) }
        .to fail_with("expected exactly the declared rows (only: notes), but:\n  missing: notes")
      expect(rows).to have_exact_rows.and have_declared_rows
      expect(partial_rows).to have_no_exact_rows.and have_declared_rows(only: :name)
    end

    it "reports each element of a collection" do
      expect { expect([rows, partial_rows]).to all(have_declared_rows(wait: 0)) }
        .to fail_with(/object at index 1 failed to match:\n\s+expected the declared rows, but:\n\s+missing: notes\n/)
      expect([rows, rows]).to all(have_exact_rows)
    end

    it "describes itself with its scope" do
      expect(have_exact_rows.description).to eq("have exact rows")
      expect(have_no_declared_fields(only: %i[email status], wait: 0).description)
        .to eq("have no declared fields (only: email, status)")
    end

    it "raises for a name that is not declared" do
      expect { expect(rows).to have_exact_rows(only: :secret) }.to raise_error(ArgumentError, /:secret is not declared/)
      lenient = ActiveAdminPageObjects::AttributesTable.new(show, rows.root_element)
      expect { expect(lenient).to have_declared_rows }.to raise_error(ArgumentError, /declares no labels/)
    end

    it "is the predicate matcher on an object that declares nothing" do
      other = Struct.new(:exact) do
        def has_exact_rows?(**) = exact
      end
      expect(other.new(true)).to have_exact_rows(only: :name)
      expect(other.new(false)).not_to have_exact_rows
      expect { expect(other.new(false)).to have_exact_rows }.to fail_with(/has_exact_rows\?` to be truthy, got false/)
      expect { expect(other.new(true)).not_to have_exact_rows }.to fail_with(/has_exact_rows\?` to be falsey, got true/)
      expect { expect(rows).to have_exact_columns }.to fail_with(/to respond to `has_exact_columns\?`/)
    end
  end

  describe "failure messages of the exact error matchers" do
    include ActiveAdminPageObjects::RSpec::Matchers

    let(:form_page) { Pages::CustomerForm.new }
    let(:form) { form_page.form }

    def fail_with(message)
      raise_error(RSpec::Expectations::ExpectationNotMetError, message)
    end

    def without_waiting(&)
      Capybara.using_wait_time(0, &)
    end

    context "with inline errors" do
      before do
        form_page.load(action: "new")
        form.fill(name: "", email: "not-an-email")
        form.submit
        expect(form).to have_exact_field_errors(name: "can't be blank", email: "is invalid")
      end

      it "lists the missing and the unexpected messages of each field" do
        expect { without_waiting { expect(form).to have_exact_field_errors(name: "is reserved", notes: "is too long") } }
          .to fail_with(<<~MESSAGE.chomp)
            expected exactly the given field errors, but:
              name: missing "is reserved"; unexpected "can't be blank"
              notes: missing "is too long"
              email: unexpected "is invalid"
          MESSAGE
        expect { without_waiting { expect(form).to have_exact_field_errors(email: ["is invalid", "is taken"]) } }
          .to fail_with(<<~MESSAGE.chomp)
            expected exactly the given field errors, but:
              email: missing "is taken"
              name: unexpected "can't be blank"
          MESSAGE
      end

      it "lists every error when none is expected" do
        expect { without_waiting { expect(form).to have_exact_field_errors } }.to fail_with(<<~MESSAGE.chomp)
          expected no field errors, but:
            name: unexpected "can't be blank"
            email: unexpected "is invalid"
        MESSAGE
        expect { without_waiting { expect(form).to have_exact_field_errors(notes: []) } }
          .to fail_with(/\Aexpected no field errors, but:\n  name: unexpected/)
      end

      it "says that the errors match when a negated matcher fails" do
        message = "expected the field errors to differ from the given ones, but they match exactly"
        errors = { "External ID" => [], name: "can't  be blank", email: ["is invalid"] }
        expect { without_waiting { expect(form).to have_no_exact_field_errors(**errors) } }.to fail_with(message)
        expect { without_waiting { expect(form).not_to have_exact_field_errors(**errors) } }.to fail_with(message)
        expect(form).to have_no_exact_field_errors(name: "can't be blank")
        expect(form).not_to have_exact_field_errors
      end

      it "asks the opposite predicate when negated" do
        allow(form).to receive(:has_no_exact_field_errors?).and_call_original
        expect(form).not_to have_exact_field_errors(email: "is invalid")
        expect(form).to have_received(:has_no_exact_field_errors?).with(email: "is invalid")
        expect { without_waiting { expect(form).not_to have_no_exact_field_errors(email: "is invalid") } }
          .to fail_with(%(expected exactly the given field errors, but:\n  name: unexpected "can't be blank"))
      end

      it "raises for a field that is not declared" do
        expect { expect(form).to have_exact_field_errors(secret: "is invalid") }
          .to raise_error(ArgumentError, /:secret is not declared/)
      end
    end

    it "says that no field shows an error" do
      form_page.load(action: "new")
      expect { without_waiting { expect(form).to have_no_exact_field_errors } }
        .to fail_with("expected a field error, but no field shows one")
      expect { expect(form).to have_no_exact_semantic_errors(wait: 0) }
        .to fail_with("expected a semantic error, but the form shows none")
      expect(form).to have_exact_field_errors.and have_exact_semantic_errors
    end

    it "reports the errors of a has_many fieldset" do
      customer.orders.create!(reference: "REF-1", state: "new", quantity: 1)
      form_page.load(id: customer.id, action: "edit")
      form.has_many(:orders).fieldset(0).fill(quantity: 0)
      form.submit
      fieldset = form.has_many(:orders).fieldset(0)
      expect(fieldset).to have_exact_field_errors(quantity: "must be greater than 0")
      expect { without_waiting { expect(fieldset).to have_exact_field_errors(reference: "can't be blank") } }
        .to fail_with(<<~MESSAGE.chomp)
          expected exactly the given field errors, but:
            reference: missing "can't be blank"
            quantity: unexpected "must be greater than 0"
        MESSAGE
    end

    context "with base errors" do
      before do
        form_page.load(action: "new")
        form.fill(name: "Reserved", email: "acme@example.com", balance: -1)
        form.submit
        expect(form).to have_exact_semantic_errors("Name is reserved", "Balance is negative", strict_order: true)
      end

      it "lists the missing and the unexpected base errors" do
        expect { expect(form).to have_exact_semantic_errors("Name is reserved", "Email is taken", wait: 0) }
          .to fail_with(<<~MESSAGE.chomp)
            expected exactly the given semantic errors, but:
              missing: "Email is taken"
              unexpected: "Balance is negative"
          MESSAGE
        expect { expect(form).to have_exact_semantic_errors("Name is reserved", "Name is reserved", wait: 0) }
          .to fail_with(<<~MESSAGE.chomp)
            expected exactly the given semantic errors, but:
              missing: "Name is reserved"
              unexpected: "Balance is negative"
          MESSAGE
        expect { expect(form).to have_exact_semantic_errors(wait: 0) }.to fail_with(<<~MESSAGE.chomp)
          expected no semantic errors, but:
            unexpected: "Name is reserved", "Balance is negative"
        MESSAGE
      end

      it "gives both orders when only the order differs" do
        expect do
          expect(form).to have_exact_semantic_errors("Balance is negative", "Name is reserved", strict_order: true, wait: 0)
        end.to fail_with(<<~MESSAGE.chomp)
          expected exactly the given semantic errors, in order, but:
            order: expected "Balance is negative", "Name is reserved", got "Name is reserved", "Balance is negative"
        MESSAGE
        expect { expect(form).to have_exact_semantic_errors("Balance is negative", strict_order: true, wait: 0) }
          .to fail_with(%(expected exactly the given semantic errors, in order, but:\n  unexpected: "Name is reserved"))
        expect(form).to have_exact_semantic_errors("Balance is negative", "Name is reserved")
      end

      it "says that the errors match when a negated matcher fails" do
        message = "expected the semantic errors to differ from the given ones, but they match exactly"
        expect { expect(form).to have_no_exact_semantic_errors("Balance is negative", "Name is reserved", wait: 0) }
          .to fail_with(message)
        expect { expect(form).not_to have_exact_semantic_errors("Name is reserved", "Balance is negative", wait: 0) }
          .to fail_with(message)
        expect(form).to have_no_exact_semantic_errors("Balance is negative", "Name is reserved", strict_order: true)
        expect(form).not_to have_exact_semantic_errors("Name is reserved")
      end
    end

    it "is the predicate matcher on another object" do
      other = Struct.new(:exact) do
        def has_exact_field_errors?(**) = exact
        def has_exact_semantic_errors?(*) = exact
      end
      expect(other.new(true)).to have_exact_field_errors(name: "can't be blank")
      expect(other.new(false)).not_to have_exact_semantic_errors("Name is reserved")
      expect { expect(other.new(false)).to have_exact_field_errors }
        .to fail_with(/has_exact_field_errors\?` to be truthy, got false/)
      expect { expect(index).to have_exact_semantic_errors }.to fail_with(/to respond to `has_exact_semantic_errors\?`/)
      expect(have_exact_field_errors.description).to eq("have exact field errors")
    end
  end

  describe "composition" do
    include ActiveAdminPageObjects::RSpec::Matchers

    it "combines with and" do
      index = Pages::CustomerIndex.new
      index.load
      expect(index).to have_page_title(text: "Customers").and have_page_title(exact_text: "Customers")
    end
  end
end
