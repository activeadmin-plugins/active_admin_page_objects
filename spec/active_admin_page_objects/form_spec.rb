# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Form do
  let(:form_page) { Pages::CustomerForm.new }
  let(:form) { form_page.form }

  before { create_category("Retail") }

  # A form over the page's element, with the fields the block declares.
  def declared_form(&)
    Class.new(described_class, &).new(form_page, form.root_element)
  end

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

    it "has the declared field labels" do
      form_page.load(action: "new")
      expect(form).to have_declared_fields
      expect(form.declared_label_mismatches).to eq({})
    end

    it "compares a declared label exactly" do
      form_page.load(action: "new")
      wrong_case = declared_form do
        field :name, "Name*"
        field :external_id, "External id"
        field :active, "active"
        field :tier, "Bronze"
        field :channels, "Channels"
        field :secret, "Secret"
      end
      expect(wrong_case).to have_no_declared_fields
      expect(wrong_case.has_declared_fields?(wait: 0)).to be(false)
      expect(wrong_case.declared_label_mismatches)
        .to eq("name" => "Name", "external_id" => "External ID", "active" => "Active", "tier" => "Tier", "secret" => nil)
      expect(declared_form { field :external_id, "External ID" }).to have_declared_fields
    end

    it "raises when a field is declared with another class" do
      form_page.load(action: "new")
      mistyped = declared_form do
        field :status, "Status", ActiveAdminPageObjects::Form::RadioInput
        field :signed_on, "Signed on", ActiveAdminPageObjects::Form::StringInput
      end
      expect { mistyped.input(:status) }.to raise_error(
        Capybara::ExpectationNotMet,
        ":status is declared as ActiveAdminPageObjects::Form::RadioInput, " \
        "but the page has ActiveAdminPageObjects::Form::SelectInput"
      )
      expect { mistyped.choose(:status, "pending") }.to raise_error(Capybara::ExpectationNotMet, /RadioInput/)
      expect(mistyped.input(:signed_on)).to be_a(ActiveAdminPageObjects::Form::DatePickerInput)
      expect(mistyped).to have_declared_fields
    end

    it "takes any key without declarations" do
      form_page.load(action: "new")
      lenient = described_class.new(form_page, form.root_element)
      expect(lenient).to have_no_input_error(:secret)
      expect { lenient.has_declared_fields? }.to raise_error(ArgumentError, /declares no labels/)
    end

    describe "typed inputs" do
      before { form_page.load(action: "new") }

      it "returns a StringInput for the text inputs" do
        %i[name email external_id balance notes website phone password].each do |key|
          expect(form.input(key)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringInput)
        end
        name = form.input(:name)
        name.fill("Acme")
        expect(name.value).to eq("Acme")
        form.fill(:notes, with: "Big account")
        expect(form.input(:notes).value).to eq("Big account")
      end

      it "returns a SelectInput for a select" do
        status = form.input(:status)
        expect(status).to be_an_instance_of(ActiveAdminPageObjects::Form::SelectInput)
        expect(status.options).to eq(%w[active pending closed])
        expect(status.selected).to be_nil
        status.choose("pending")
        expect(status.selected).to eq("pending")
        status.fill("closed")
        expect(status.selected).to eq("closed")
      end

      it "returns a BooleanInput for a boolean" do
        active = form.input(:active)
        expect(active).to be_an_instance_of(ActiveAdminPageObjects::Form::BooleanInput)
        expect(active).to be_checked
        active.fill(false)
        expect(active).not_to be_checked
      end

      it "returns a RadioInput for a radio" do
        tier = form.input(:tier)
        expect(tier).to be_an_instance_of(ActiveAdminPageObjects::Form::RadioInput)
        expect(tier.options).to eq(%w[Bronze Silver Gold])
        expect(tier.selected).to be_nil
        tier.choose("Gold")
        expect(tier.selected).to eq("Gold")
        form.choose(:tier, "Silver")
        expect(tier.selected).to eq("Silver")
      end

      it "returns a CheckBoxesInput for check_boxes" do
        channels = form.input(:channels)
        expect(channels).to be_an_instance_of(ActiveAdminPageObjects::Form::CheckBoxesInput)
        expect(channels.checked).to eq([])
        channels.check("Email", "Post")
        expect(channels.checked).to eq(%w[Email Post])
        channels.uncheck("Email")
        expect(channels.checked).to eq(["Post"])
      end

      it "returns a DatePickerInput for a datepicker" do
        signed_on = form.input(:signed_on)
        expect(signed_on).to be_an_instance_of(ActiveAdminPageObjects::Form::DatePickerInput)
        signed_on.fill("2026-01-31")
        expect(signed_on.value).to eq("2026-01-31")
        form.fill(:signed_on, with: Date.new(2026, 2, 28))
        expect(signed_on.value).to eq("2026-02-28")
      end

      it "saves what the typed inputs set" do
        form.fill(:name, with: "Acme")
        form.fill(:email, with: "acme@example.com")
        form.fill(:website, with: "https://acme.example.com")
        form.fill(:phone, with: "+1 555 0100")
        form.choose(:tier, "Gold")
        form.input(:channels).check("Email", "Post")
        form.fill(:signed_on, with: "2026-01-31")
        form.submit

        expect(form_page.flashes).to have_flash(:notice, "Customer was successfully created.")
        expect(Customer.last).to have_attributes(website: "https://acme.example.com", phone: "+1 555 0100", tier: "Gold",
                                                 channels: %w[Email Post], signed_on: Date.new(2026, 1, 31))
      end
    end
  end

  it_behaves_like "resource form"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "resource form"
  end

  describe "declared fields" do
    let(:strict_class) do
      Class.new(described_class) do
        field :name, "Name", ActiveAdminPageObjects::Form::StringInput
        field :external_id, "External ID"
      end
    end

    it "rejects an undeclared key before it queries the page" do
      strict = strict_class.new(nil, nil)
      message = /:email is not declared; declared keys: name, external_id/
      expect { strict.input(:email) }.to raise_error(ArgumentError, message)
      expect { strict.fill(:email, with: "a@example.com") }.to raise_error(ArgumentError, message)
      expect { strict.choose(:email, "a@example.com") }.to raise_error(ArgumentError, message)
      expect { strict.has_input_error?(:email) }.to raise_error(ArgumentError, message)
      expect { strict.has_no_input_error?(:email) }.to raise_error(ArgumentError, message)
    end

    it "takes a declared key as a symbol, a string or a label" do
      form_page.load(action: "new")
      strict = strict_class.new(form_page, form.root_element)
      strict.fill(:external_id, with: "X-1")
      expect(strict.input("external_id").value).to eq("X-1")
      expect(strict.input("External ID").value).to eq("X-1")
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) { field :email, "Email" }
      expect(subclass.declarations.keys).to eq(%w[name external_id email])
      expect(subclass.declarations["name"]).to eq(label: "Name", type: ActiveAdminPageObjects::Form::StringInput)
      expect(strict_class.declarations.keys).to eq(%w[name external_id])
      expect(described_class.declarations).to be_empty
    end
  end

  describe ".register_type" do
    it "registers a section for another input class" do
      custom = Class.new(described_class::Input)
      described_class.register_type("datepicker", custom)
      form_page.load(action: "new")
      expect(described_class.new(form_page, form.root_element).input(:signed_on)).to be_a(custom)
    ensure
      described_class.register_type("datepicker", described_class::DatePickerInput)
    end
  end
end
