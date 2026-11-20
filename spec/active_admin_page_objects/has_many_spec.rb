# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::HasMany do
  let(:form_page) { Pages::CustomerForm.new }
  let(:form) { form_page.form }
  let(:orders) { form.has_many(:orders) }
  let(:customer) { create_customer(status: "pending") }

  def create_order(reference, state, quantity)
    Order.create!(customer: customer, reference: reference, state: state, quantity: quantity)
  end

  context "when editing a customer with two orders" do
    let!(:first_order) { create_order("REF-1", "paid", 2) }
    let!(:second_order) { create_order("REF-B1", "new", 1) }

    before { form_page.load(id: customer.id, action: "edit") }

    it "reads the heading and counts the fieldsets" do
      expect(orders.heading).to eq("Orders")
      expect(orders.count).to eq(2)
      expect(orders.fieldsets.size).to eq(2)
      expect(orders).to have_fieldsets(count: 2)
      expect(orders).to have_no_fieldsets(count: 3)
    end

    it "reads the inputs of a fieldset by index" do
      expect(orders.fieldset(0).input(:reference)).to have_field(with: "REF-1")
      expect(orders.fieldset(1).input(:reference)).to have_field(with: "REF-B1")
      expect(orders.fieldset(0).input(:quantity)).to have_field(with: "2")
      expect(orders.fieldset(0).input(:quantity)).to be_a(ActiveAdminPageObjects::Form::StringInput)
      expect(orders.fieldset(0).input(:state).selected).to eq("paid")
    end

    it "adds a fieldset, fills it and saves the order" do
      fieldset = orders.add
      expect(orders).to have_fieldsets(count: 3)
      fieldset.fill(:reference, with: "REF-NEW")
      fieldset.choose(:state, "shipped")
      fieldset.fill(:quantity, with: 5)
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully updated.")
      expect(customer.orders.pluck(:reference)).to match_array(%w[REF-1 REF-B1 REF-NEW])
      expect(customer.orders.find_by(reference: "REF-NEW")).to have_attributes(state: "shipped", quantity: 5)
    end

    it "removes a new fieldset with its remove link" do
      orders.add
      expect(orders).to have_fieldsets(count: 3)
      orders.remove(2)
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

  context "when creating a customer" do
    before { form_page.load(action: "new") }

    it "starts without fieldsets" do
      expect(orders.count).to eq(0)
      expect(orders).to have_no_fieldsets
    end

    it "adds a fieldset and saves the customer with its order" do
      form.fill(:name, with: "Acme")
      form.fill(:email, with: "acme@example.com")
      orders.add.fill(:reference, with: "REF-NEW")
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully created.")
      expect(Customer.last.orders.pluck(:reference)).to eq(["REF-NEW"])
    end
  end
end
