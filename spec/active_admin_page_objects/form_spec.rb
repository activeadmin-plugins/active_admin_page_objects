# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Form do
  let(:form_page) { Pages::CustomerForm.new }
  let(:form) { form_page.form }

  before { create_category("Retail") }

  shared_examples "resource form" do
    it "fills every input type and submits" do
      form_page.load(action: "new")
      form.fill(:name, with: "Acme")
      form.fill(:email, with: "acme@example.com")
      form.choose(:status, "pending")
      form.fill(:category, with: "Retail")
      form.fill(:balance, with: 12.5)
      form.fill(:active, with: false)
      form.fill(:notes, with: "Big account")
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully created.")
      customer = Customer.last
      expect(customer).to have_attributes(name: "Acme", email: "acme@example.com", status: "pending",
                                          balance: 12.5, active: false, notes: "Big account")
      expect(customer.category.name).to eq("Retail")
    end

    it "shows inline and base errors" do
      form_page.load(action: "new")
      form.fill(:name, with: "Reserved")
      form.fill(:email, with: "not-an-email")
      form.submit

      expect(form).to have_input_error(:email, "is invalid")
      expect(form).to have_input_error(:email)
      expect(form).to have_no_input_error(:name)
      expect(form).to have_no_input_error(:email, "can't be blank")
      expect(form).to have_semantic_errors("Name is reserved")
      expect(form).to have_semantic_errors
      expect(form).to have_no_semantic_errors("Email is taken")
      expect(form.semantic_errors).to eq(["Name is reserved"])
      expect(form.input(:email).errors).to eq(["is invalid"])
    end

    it "edits an existing record" do
      customer = create_customer(name: "Old")
      form_page.load(id: customer.id, action: "edit")
      expect(form).to have_no_semantic_errors
      expect(form.input(:name)).to have_field(with: "Old")
      form.fill(:name, with: "New")
      form.submit
      expect(customer.reload.name).to eq("New")
    end
  end

  it_behaves_like "resource form"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "resource form"
  end
end
