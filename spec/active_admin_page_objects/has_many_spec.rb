# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::HasMany do
  let(:form_page) { Pages::OrderForm.new }
  let(:form) { form_page.form }
  let(:line_items) { form.has_many(:line_items) }
  let(:customer) { create_customer }
  let(:order) { Order.create!(customer: customer, reference: "ORD-1", state: "new", quantity: 1) }

  def create_line_item(sku, kind, quantity)
    LineItem.create!(order: order, sku: sku, kind: kind, quantity: quantity)
  end

  # A form over the page's element, with the fields and has_many blocks the block declares.
  def declared_form(&)
    Class.new(ActiveAdminPageObjects::Form, &).new(form_page, form.root_element)
  end

  # The line_items has_many of the form, with the fieldset fields the block declares.
  def declared_line_items(&)
    declared_form { has_many(:line_items, "Line Items", &) }.has_many(:line_items)
  end

  shared_examples "saved fieldsets" do
    before do
      create_line_item("SKU-1", "Goods", 2)
      create_line_item("SKU-B1", "Service", 1)
      form_page.load(id: order.id, action: "edit")
    end

    it "reads the heading and counts the fieldsets" do
      expect(line_items.heading).to eq("Line Items")
      expect(line_items.count).to eq(2)
      expect(line_items.fieldsets.size).to eq(2)
      expect(line_items).to have_fieldsets(count: 2)
      expect(line_items).to have_no_fieldsets(count: 3)
    end

    it "reads the declared fields of a fieldset by index" do
      expect(line_items.fieldset(0).field(:sku)).to have_field(with: "SKU-1")
      expect(line_items.fieldset(1).field(:sku).value).to eq("SKU-B1")
      expect(line_items.fieldset(0).field(:quantity).value).to eq("2")
      expect(line_items.fieldset(0).field(:quantity)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(line_items.fieldset(0).field(:kind).selected).to eq("Goods")
      expect(line_items.fieldsets.map { |fieldset| fieldset.field(:sku).value }).to eq(%w[SKU-1 SKU-B1])
      expect { line_items.fieldset(0).field(:price) }
        .to raise_error(ArgumentError, /:price is not declared; declared keys: sku, kind, quantity/)
    end

    it "types the fields of an undeclared has_many by the page" do
      fieldset = ActiveAdminPageObjects::Form.new(form_page, form.root_element).has_many(:line_items).fieldset(0)
      expect(fieldset).to be_an_instance_of(described_class::Fieldset)
      expect(fieldset.field(:sku)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(fieldset.field(:kind)).to be_an_instance_of(ActiveAdminPageObjects::Form::SelectField)
      expect { fieldset.has_exact_fields? }.to raise_error(ArgumentError, /declares no labels/)
    end

    it "has the declared fields in each fieldset and no other" do
      expect(line_items).to have_fieldsets(count: 2)
      expect(line_items.fieldsets).to all(have_declared_fields)
      expect(line_items.fieldsets).to all(have_exact_fields)
      expect(line_items.fieldset(1).exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "reports the fieldset fields that differ from the declared ones" do
      partial = declared_line_items do
        field :sku, "Code", ActiveAdminPageObjects::Form::StringField
        field :kind, "Kind", ActiveAdminPageObjects::Form::SelectField
        field :price, "Price", ActiveAdminPageObjects::Form::StringField
      end
      fieldset = partial.fieldset(0)
      expect(fieldset.field(:sku).value).to eq("SKU-1")
      expect(fieldset).to have_no_exact_fields
      expect(fieldset).to have_no_declared_fields
      expect(fieldset.declared_label_mismatches).to eq("sku" => "Sku", "price" => nil)
      expect(fieldset.exact_mismatches).to eq(missing: ["price"], unexpected: ["quantity"], labels: { "sku" => "Sku" })
      expect(fieldset).to have_exact_fields(only: :kind)
      expect(fieldset).to have_declared_fields(except: %i[sku price])
    end

    it "builds the class a fieldset field is declared with" do
      select_class = Class.new(ActiveAdminPageObjects::Form::SelectField)
      typed = declared_line_items do
        field :kind, "Kind", select_class
        field :sku, "Sku", ActiveAdminPageObjects::Form::SelectField
      end
      expect(typed.fieldset(0).field(:kind)).to be_an_instance_of(select_class)
      expect { typed.fieldset(0).field(:sku) }
        .to raise_error(ActiveAdminPageObjects::DeclaredClassMismatch, /SelectField, but the page has .*StringField/)
    end

    it "compares the inline errors of a fieldset" do
      line_items.fieldset(1).fill(sku: "SKU-B2", quantity: 0)
      form.submit

      expect(form).to have_field_errors
      expect(form).to have_exact_field_errors
      expect(line_items.fieldset(0)).to have_no_field_errors
      expect(line_items.fieldset(0)).to have_exact_field_errors
      expect(line_items.fieldset(1)).to have_field_errors
      expect(line_items.fieldset(1)).to have_field_error(:quantity, "must be greater than 0")
      expect(line_items.fieldset(1)).to have_no_field_error(:sku)
      expect(line_items.fieldset(1)).to have_exact_field_errors(quantity: "must be greater than 0")
      expect(line_items.fieldset(1)).to have_no_exact_field_errors
      expect(line_items.fieldset(1)).to have_no_exact_field_errors(sku: "must be greater than 0")
      Capybara.using_wait_time(0) { expect(form.has_no_field_errors?).to be(false) }
    end
  end

  it_behaves_like "saved fieldsets"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "saved fieldsets"
  end

  context "when editing an order with two line items" do
    before do
      create_line_item("SKU-1", "Goods", 2)
      create_line_item("SKU-B1", "Service", 1)
      form_page.load(id: order.id, action: "edit")
    end

    it "adds a fieldset, fills it and saves the line item" do
      fieldset = line_items.add
      expect(line_items).to have_fieldsets(count: 3)
      expect(fieldset).to have_exact_fields
      fieldset.fill(sku: "SKU-NEW", kind: "Service", quantity: 5)
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Order was successfully updated.")
      expect(order.line_items.pluck(:sku)).to match_array(%w[SKU-1 SKU-B1 SKU-NEW])
      expect(order.line_items.find_by(sku: "SKU-NEW")).to have_attributes(kind: "Service", quantity: 5)
    end

    it "leaves a hidden fieldset field out unless it is declared or queried with visible: :all" do
      hide("#order_line_items_attributes_0_quantity_input")
      fieldset = line_items.fieldset(0)
      Capybara.using_wait_time(0) do
        expect { fieldset.field(:quantity) }.to raise_error(Capybara::ElementNotFound)
        expect(fieldset.has_exact_fields?).to be(false)
      end
      expect(fieldset.exact_mismatches).to eq(missing: ["quantity"], unexpected: [], labels: {})
      expect(fieldset.field(:quantity, visible: :all)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(fieldset).to have_exact_fields(visible: :all)
      expect(line_items.fieldset(1)).to have_exact_fields

      partial = declared_line_items { field :sku, "Sku", ActiveAdminPageObjects::Form::StringField }.fieldset(0)
      expect(partial.exact_mismatches[:unexpected]).to eq(["kind"])
      expect(partial.exact_mismatches(visible: :all)[:unexpected]).to eq(%w[kind quantity])

      declared = declared_line_items do
        field :sku, "Sku", ActiveAdminPageObjects::Form::StringField
        field :kind, "Kind", ActiveAdminPageObjects::Form::SelectField
        field :quantity, "Quantity", ActiveAdminPageObjects::Form::StringField, visible: :all
      end
      expect(declared).to have_fieldsets(count: 2)
      expect(declared.fieldsets).to all(have_exact_fields)
      expect(declared.fieldset(0).field(:quantity)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
    end

    it "removes a new fieldset with its remove link" do
      line_items.add
      expect(line_items).to have_fieldsets(count: 3)
      line_items.remove(2)
      expect(line_items).to have_fieldsets(count: 2)
    end

    it "raises when a fieldset has neither a remove link nor a delete checkbox" do
      page.execute_script("document.querySelectorAll('li.has-many-delete').forEach((node) => node.remove())")
      expect { line_items.remove(0) }.to raise_error(ArgumentError, /no remove link and no delete checkbox/)
      expect(line_items).to have_fieldsets(count: 2)
    end

    it "marks a saved fieldset for deletion and destroys the line item on save" do
      expect(line_items.fieldset(0)).not_to be_marked_for_destroy
      line_items.remove(0)
      expect(line_items.fieldset(0)).to be_marked_for_destroy
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Order was successfully updated.")
      expect(order.line_items.pluck(:sku)).to eq(["SKU-B1"])
    end
  end

  # The dummy form puts a check_boxes input first for this order: its
  # hidden input is named `order[line_items_attributes][0][tags][]`.
  shared_examples "a fieldset that starts with a check_boxes input" do
    let(:order) { Order.create!(customer: customer, reference: "LINE-TAGS") }

    # Found again on each call: the form is rendered anew after a submit.
    def fieldset
      ActiveAdminPageObjects::Form.new(form_page, form_page.form.root_element).has_many(:line_items).fieldset(0)
    end

    before do
      create_line_item("SKU-1", "Goods", 2)
      form_page.load(id: order.id, action: "edit")
    end

    it "finds the fields by the fieldset prefix" do
      expect(fieldset.field(:tags)).to be_an_instance_of(ActiveAdminPageObjects::Form::CheckBoxesField)
      expect(fieldset.field(:sku).value).to eq("SKU-1")
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

  context "when creating an order" do
    before do
      customer
      form_page.load(action: "new")
    end

    it "starts without fieldsets" do
      expect(line_items.count).to eq(0)
      expect(line_items).to have_no_fieldsets
    end

    it "adds a fieldset and saves the order with its line item" do
      form.fill(reference: "ORD-NEW", customer: customer.name)
      line_items.add.field(:sku).fill("SKU-NEW")
      line_items.add.fill(sku: "SKU-2", kind: "Service")
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Order was successfully created.")
      expect(Order.last.line_items.pluck(:sku)).to eq(%w[SKU-NEW SKU-2])
    end
  end

  describe "the has_many block of the form" do
    before { form_page.load(action: "new") }

    it "counts the block once, as its declared element" do
      expect(form).to have_exact_fields
      expect(form).to have_declared_fields
      expect(form.exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
      expect(form.declared_label_mismatches).to eq({})
    end

    it "does not count the inputs of its fieldsets" do
      line_items.add
      expect(form).to have_exact_fields
      expect(form.exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "reports a block that is not declared, or declared with another heading" do
      fields = lambda do |heading|
        declared_form do
          field :reference, "Reference", ActiveAdminPageObjects::Form::StringField
          field :state, "State", ActiveAdminPageObjects::Form::SelectField
          field :quantity, "Quantity", ActiveAdminPageObjects::Form::StringField
          field :customer, "Customer", ActiveAdminPageObjects::Form::SelectField
          has_many :line_items, heading if heading
        end
      end
      expect(fields.call(nil).exact_mismatches).to eq(missing: [], unexpected: ["line_items"], labels: {})
      expect(fields.call("Items").exact_mismatches).to eq(missing: [], unexpected: [], labels: { "line_items" => "Line Items" })
    end

    it "reports a declared block the page lacks" do
      absent = declared_form { has_many :parts, "Parts" }
      expect(absent.declared_label_mismatches).to eq("parts" => nil)
    end

    it "is not a field" do
      expect { form.field(:line_items) }.to raise_error(ArgumentError, /:line_items is declared as a has_many, not as a field/)
      expect { form.has_many(:orders) }.to raise_error(ArgumentError, /:orders is not declared; declared keys: line_items/)
    end

    it "is found when hidden only with visible: :all, or when declared with it" do
      hide(".has-many-container")
      Capybara.using_wait_time(0) do
        expect { form.has_many(:line_items) }.to raise_error(Capybara::ElementNotFound)
        expect(form.has_exact_fields?).to be(false)
      end
      expect(form.has_many(:line_items, visible: :all)).to be_a(described_class)
      expect(form).to have_exact_fields(visible: :all)
      expect(declared_form { has_many :line_items, "Line Items", visible: :all }.has_many(:line_items)).to be_a(described_class)
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
