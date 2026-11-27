# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::HasMany do
  let(:form_page) { Pages::CustomerForm.new }
  let(:form) { form_page.form }
  let(:orders) { form.has_many(:orders) }
  let(:customer) { create_customer(status: "pending") }

  def create_order(reference, state, quantity)
    Order.create!(customer: customer, reference: reference, state: state, quantity: quantity)
  end

  # The orders has_many of the form, with the fieldset fields the block declares.
  def declared_orders(&)
    form_class = Class.new(ActiveAdminPageObjects::Form) { has_many(:orders, "Orders", &) }
    form_class.new(form_page, form.root_element).has_many(:orders)
  end

  shared_examples "saved fieldsets" do
    before do
      create_order("REF-1", "paid", 2)
      create_order("REF-B1", "new", 1)
      form_page.load(id: customer.id, action: "edit")
    end

    it "reads the heading and counts the fieldsets" do
      expect(orders.heading).to eq("Orders")
      expect(orders.count).to eq(2)
      expect(orders.fieldsets.size).to eq(2)
      expect(orders).to have_fieldsets(count: 2)
      expect(orders).to have_no_fieldsets(count: 3)
    end

    it "reads the declared fields of a fieldset by index" do
      expect(orders.fieldset(0).field(:reference)).to have_field(with: "REF-1")
      expect(orders.fieldset(1).field(:reference).value).to eq("REF-B1")
      expect(orders.fieldset(0).field(:quantity).value).to eq("2")
      expect(orders.fieldset(0).field(:quantity)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(orders.fieldset(0).field(:state).selected).to eq("paid")
      expect(orders.fieldsets.map { |fieldset| fieldset.field(:reference).value }).to eq(%w[REF-1 REF-B1])
      expect { orders.fieldset(0).field(:price) }
        .to raise_error(ArgumentError, /:price is not declared; declared keys: reference, state, quantity/)
    end

    it "types the fields of an undeclared has_many by the page" do
      fieldset = ActiveAdminPageObjects::Form.new(form_page, form.root_element).has_many(:orders).fieldset(0)
      expect(fieldset).to be_an_instance_of(described_class::Fieldset)
      expect(fieldset.field(:reference)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(fieldset.field(:state)).to be_an_instance_of(ActiveAdminPageObjects::Form::SelectField)
      expect { fieldset.has_exact_fields? }.to raise_error(ArgumentError, /declares no labels/)
    end

    it "has the declared fields in each fieldset and no other" do
      expect(orders).to have_fieldsets(count: 2)
      expect(orders.fieldsets).to all(have_declared_fields)
      expect(orders.fieldsets).to all(have_exact_fields)
      expect(orders.fieldset(1).exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "reports the fieldset fields that differ from the declared ones" do
      partial = declared_orders do
        field :reference, "Code", ActiveAdminPageObjects::Form::StringField
        field :state, "State", ActiveAdminPageObjects::Form::SelectField
        field :price, "Price", ActiveAdminPageObjects::Form::StringField
      end
      fieldset = partial.fieldset(0)
      expect(fieldset.field(:reference).value).to eq("REF-1")
      expect(fieldset).to have_no_exact_fields
      expect(fieldset).to have_no_declared_fields
      expect(fieldset.declared_label_mismatches).to eq("reference" => "Reference", "price" => nil)
      expect(fieldset.exact_mismatches).to eq(missing: ["price"], unexpected: ["quantity"],
                                              labels: { "reference" => "Reference" })
      expect(fieldset).to have_exact_fields(only: :state)
      expect(fieldset).to have_declared_fields(except: %i[reference price])
    end

    it "builds the class a fieldset field is declared with" do
      select_class = Class.new(ActiveAdminPageObjects::Form::SelectField)
      typed = declared_orders do
        field :state, "State", select_class
        field :reference, "Reference", ActiveAdminPageObjects::Form::SelectField
      end
      expect(typed.fieldset(0).field(:state)).to be_an_instance_of(select_class)
      expect { typed.fieldset(0).field(:reference) }
        .to raise_error(Capybara::ExpectationNotMet, /SelectField, but the page has .*StringField/)
    end

    it "compares the inline errors of a fieldset" do
      orders.fieldset(1).fill(reference: "REF-B2", quantity: 0)
      form.submit

      expect(form).to have_field_errors
      expect(form).to have_exact_field_errors
      expect(orders.fieldset(0)).to have_no_field_errors
      expect(orders.fieldset(0)).to have_exact_field_errors
      expect(orders.fieldset(1)).to have_field_errors
      expect(orders.fieldset(1)).to have_field_error(:quantity, "must be greater than 0")
      expect(orders.fieldset(1)).to have_no_field_error(:reference)
      expect(orders.fieldset(1)).to have_exact_field_errors(quantity: "must be greater than 0")
      expect(orders.fieldset(1)).to have_no_exact_field_errors
      expect(orders.fieldset(1)).to have_no_exact_field_errors(reference: "must be greater than 0")
      Capybara.using_wait_time(0) { expect(form.has_no_field_errors?).to be(false) }
    end
  end

  it_behaves_like "saved fieldsets"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "saved fieldsets"
  end

  context "when editing a customer with two orders" do
    before do
      create_order("REF-1", "paid", 2)
      create_order("REF-B1", "new", 1)
      form_page.load(id: customer.id, action: "edit")
    end

    it "adds a fieldset, fills it and saves the order" do
      fieldset = orders.add
      expect(orders).to have_fieldsets(count: 3)
      expect(fieldset).to have_exact_fields
      fieldset.fill(reference: "REF-NEW", state: "shipped", quantity: 5)
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully updated.")
      expect(customer.orders.pluck(:reference)).to match_array(%w[REF-1 REF-B1 REF-NEW])
      expect(customer.orders.find_by(reference: "REF-NEW")).to have_attributes(state: "shipped", quantity: 5)
    end

    it "leaves a hidden fieldset field out unless it is declared or queried with visible: :all" do
      hide("#customer_orders_attributes_0_quantity_input")
      fieldset = orders.fieldset(0)
      Capybara.using_wait_time(0) do
        expect { fieldset.field(:quantity) }.to raise_error(Capybara::ElementNotFound)
        expect(fieldset.has_exact_fields?).to be(false)
      end
      expect(fieldset.exact_mismatches).to eq(missing: ["quantity"], unexpected: [], labels: {})
      expect(fieldset.field(:quantity, visible: :all)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(fieldset).to have_exact_fields(visible: :all)
      expect(orders.fieldset(1)).to have_exact_fields

      partial = declared_orders { field :reference, "Reference", ActiveAdminPageObjects::Form::StringField }.fieldset(0)
      expect(partial.exact_mismatches[:unexpected]).to eq(["state"])
      expect(partial.exact_mismatches(visible: :all)[:unexpected]).to eq(%w[state quantity])

      declared = declared_orders do
        field :reference, "Reference", ActiveAdminPageObjects::Form::StringField
        field :state, "State", ActiveAdminPageObjects::Form::SelectField
        field :quantity, "Quantity", ActiveAdminPageObjects::Form::StringField, visible: :all
      end
      expect(declared).to have_fieldsets(count: 2)
      expect(declared.fieldsets).to all(have_exact_fields)
      expect(declared.fieldset(0).field(:quantity)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
    end

    it "removes a new fieldset with its remove link" do
      orders.add
      expect(orders).to have_fieldsets(count: 3)
      orders.remove(2)
      expect(orders).to have_fieldsets(count: 2)
    end

    it "raises when a fieldset has neither a remove link nor a delete checkbox" do
      page.execute_script("document.querySelectorAll('li.has_many_delete').forEach((node) => node.remove())")
      expect { orders.remove(0) }.to raise_error(ArgumentError, /no remove link and no delete checkbox/)
      expect(orders).to have_fieldsets(count: 2)
    end

    it "marks a saved fieldset for deletion and destroys the order on save" do
      expect(orders.fieldset(0)).not_to be_marked_for_destroy
      orders.remove(0)
      expect(orders.fieldset(0)).to be_marked_for_destroy
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully updated.")
      expect(customer.orders.pluck(:reference)).to eq(["REF-B1"])
    end
  end

  # The dummy form puts a check_boxes input first for this customer: its
  # hidden input is named `customer[orders_attributes][0][tags][]`.
  shared_examples "a fieldset that starts with a check_boxes input" do
    let(:customer) { create_customer(external_id: "ORDER-TAGS") }

    # Found again on each call: the form is rendered anew after a submit.
    def fieldset
      ActiveAdminPageObjects::Form.new(form_page, form_page.form.root_element).has_many(:orders).fieldset(0)
    end

    before do
      create_order("REF-1", "paid", 2)
      form_page.load(id: customer.id, action: "edit")
    end

    it "finds the fields by the fieldset prefix" do
      expect(fieldset.field(:tags)).to be_an_instance_of(ActiveAdminPageObjects::Form::CheckBoxesField)
      expect(fieldset.field(:reference).value).to eq("REF-1")
      expect(fieldset).to have_enabled_field(:quantity)
    end

    it "sees the inline errors of the fieldset" do
      fieldset.fill(quantity: 0)
      form.submit

      expect(fieldset).to have_field_error(:quantity, "must be greater than 0")
      expect(fieldset).to have_exact_field_errors(quantity: "must be greater than 0")
      expect(fieldset.has_no_field_error?(:quantity, wait: 0)).to be(false)
      Capybara.using_wait_time(0) { expect(fieldset.has_exact_field_errors?).to be(false) }
    end
  end

  it_behaves_like "a fieldset that starts with a check_boxes input"

  context "with rack_test and a leading check_boxes input", driver: :rack_test do
    it_behaves_like "a fieldset that starts with a check_boxes input"
  end

  context "when creating a customer" do
    before { form_page.load(action: "new") }

    it "starts without fieldsets" do
      expect(orders.count).to eq(0)
      expect(orders).to have_no_fieldsets
    end

    it "adds a fieldset and saves the customer with its order" do
      form.fill(name: "Acme", email: "acme@example.com")
      orders.add.field(:reference).fill("REF-NEW")
      form.add_order("REF-2")
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully created.")
      expect(Customer.last.orders.pluck(:reference)).to eq(%w[REF-NEW REF-2])
    end
  end

  describe ".fieldset_class" do
    it "defaults to Fieldset and is inherited" do
      custom = Class.new(described_class::Fieldset)
      parent = Class.new(described_class) { self.fieldset_class = custom }
      expect(described_class.fieldset_class).to eq(described_class::Fieldset)
      expect(parent.fieldset_class).to eq(custom)
      expect(Class.new(parent).fieldset_class).to eq(custom)
    end
  end
end
