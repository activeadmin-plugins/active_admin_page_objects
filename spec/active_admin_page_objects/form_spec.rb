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
    it "fills every field type and submits" do
      form_page.load(action: "new")
      form.fill(name: "Acme", email: "acme@example.com", status: "pending", category: "Retail",
                balance: 12.5, active: false, notes: "Big account")
      form.submit

      expect(form_page.flashes).to have_flash(:notice, "Customer was successfully created.")
      customer = Customer.last
      expect(customer).to have_attributes(name: "Acme", email: "acme@example.com", status: "pending",
                                          balance: 12.5, active: false, notes: "Big account")
      expect(customer.category.name).to eq("Retail")
    end

    it "shows inline and base errors" do
      form_page.load(action: "new")
      form.fill(name: "Reserved", email: "not-an-email")
      form.submit

      expect(form).to have_field_error(:email, "is invalid")
      expect(form).to have_field_error(:email)
      expect(form).to have_no_field_error(:name)
      expect(form).to have_no_field_error(:email, "can't be blank")
      expect(form).to have_field_errors
      expect(form).to have_semantic_errors("Name is reserved")
      expect(form).to have_semantic_errors
      expect(form).to have_no_semantic_errors("Email is taken")
      expect(form.semantic_errors).to eq(["Name is reserved"])
      expect(form.field(:email).errors).to eq(["is invalid"])
    end

    it "compares the base errors exactly" do
      form_page.load(action: "new")
      form.fill(name: "Reserved", email: "acme@example.com", balance: -1)
      form.submit

      expect(form).to have_exact_semantic_errors("Balance is negative", "Name is reserved")
      expect(form).to have_exact_semantic_errors("Name is reserved", "Balance is negative", strict_order: true)
      expect(form).to have_no_exact_semantic_errors("Balance is negative", "Name is reserved", strict_order: true)
      expect(form).to have_no_exact_semantic_errors("Name is reserved")
      expect(form).to have_no_exact_semantic_errors("Name is reserved", "Balance is negative", "Email is taken")
      expect(form).to have_no_exact_semantic_errors("name is reserved", "Balance is negative")
      expect(form).to have_no_exact_semantic_errors
      expect(form.has_exact_semantic_errors?("Name is reserved", wait: 0)).to be(false)
      expect(form.has_no_exact_semantic_errors?("Name is reserved", "Balance is negative", wait: 0)).to be(false)
      expect(form).to have_no_field_errors
      expect(form).to have_exact_field_errors
    end

    it "compares the inline errors exactly" do
      form_page.load(action: "new")
      form.fill(name: "", email: "not-an-email")
      form.submit

      expect(form).to have_exact_field_errors(name: "can't be blank", email: ["is invalid"])
      expect(form).to have_exact_field_errors(name: "can't be blank", email: "is invalid", notes: [])
      expect(form).to have_no_exact_field_errors(email: "is invalid")
      expect(form).to have_no_exact_field_errors(name: "can't be blank", email: "is")
      expect(form).to have_no_exact_field_errors(name: "can't be blank", email: ["is invalid", "is taken"])
      expect(form).to have_no_exact_field_errors
      expect(form).to have_exact_semantic_errors
      Capybara.using_wait_time(0) do
        expect(form.has_exact_field_errors?(email: "is invalid")).to be(false)
        expect(form.has_no_exact_field_errors?(name: "can't be blank", email: "is invalid")).to be(false)
        expect(form.has_no_field_errors?).to be(false)
      end
    end

    it "names the exact inline errors by attribute without declarations" do
      form_page.load(action: "new")
      lenient = described_class.new(form_page, form.root_element)
      lenient.fill(email: "not-an-email")
      lenient.submit

      lenient = described_class.new(form_page, form.root_element)
      expect(lenient).to have_exact_field_errors(name: "can't be blank", email: "is invalid")
      expect(lenient).to have_no_exact_field_errors(name: "can't be blank")
    end

    it "edits an existing record" do
      customer = create_customer(name: "Old")
      form_page.load(id: customer.id, action: "edit")
      expect(form).to have_no_semantic_errors
      expect(form).to have_no_field_errors
      expect(form.field(:name)).to have_field(with: "Old")
      form.field(:name).fill("New")
      form.submit
      expect(customer.reload.name).to eq("New")
    end

    it "has the declared field labels and no other field" do
      form_page.load(action: "new")
      expect(form).to have_declared_fields
      expect(form).to have_exact_fields
      expect(form.declared_label_mismatches).to eq({})
      expect(form.exact_mismatches).to eq(missing: [], unexpected: [], labels: {})
    end

    it "compares a declared label exactly" do
      form_page.load(action: "new")
      wrong_case = declared_form do
        field :name, "Name*", ActiveAdminPageObjects::Form::StringField
        field :external_id, "External id", ActiveAdminPageObjects::Form::StringField
        field :active, "active", ActiveAdminPageObjects::Form::BooleanField
        field :tier, "Bronze", ActiveAdminPageObjects::Form::RadioField
        field :channels, "Channels", ActiveAdminPageObjects::Form::CheckBoxesField
        field :secret, "Secret", ActiveAdminPageObjects::Form::StringField
      end
      expect(wrong_case).to have_no_declared_fields
      expect(wrong_case.has_declared_fields?(wait: 0)).to be(false)
      expect(wrong_case.declared_label_mismatches).to eq(
        "name" => "Name", "external_id" => "External ID", "active" => "Active", "tier" => "Tier", "secret" => nil
      )
      expect(wrong_case).to have_declared_fields(only: :channels)
      expect(wrong_case).to have_no_declared_fields(only: %i[channels tier])
      expect(wrong_case).to have_declared_fields(except: %i[name external_id active tier secret])
      external_id = declared_form { field :external_id, "External ID", ActiveAdminPageObjects::Form::StringField }
      expect(external_id).to have_declared_fields
    end

    it "reports the fields that are missing, not declared or labelled otherwise" do
      form_page.load(action: "new")
      partial = declared_form do
        field :email, "E-mail", ActiveAdminPageObjects::Form::StringField
        field :status, "Status", ActiveAdminPageObjects::Form::SelectField
        field :secret, "Secret", ActiveAdminPageObjects::Form::StringField
      end
      expect(partial).to have_no_exact_fields
      expect(partial.has_exact_fields?(wait: 0)).to be(false)
      expect(partial.exact_mismatches).to eq(
        missing: ["secret"],
        unexpected: %w[name external_id category balance active notes website phone password tier channels signed_on orders],
        labels: { "email" => "Email" }
      )
    end

    it "narrows the exact fields with only and except" do
      form_page.load(action: "new")
      partial = declared_form do
        field :email, "Email", ActiveAdminPageObjects::Form::StringField
        field :status, "Status", ActiveAdminPageObjects::Form::SelectField
        field :secret, "Secret", ActiveAdminPageObjects::Form::StringField
      end
      expect(partial).to have_exact_fields(only: %i[email status])
      expect(partial).to have_no_exact_fields(only: %i[email secret])
      expect(partial.exact_mismatches(only: :secret)).to eq(missing: ["secret"], unexpected: [], labels: {})
      expect(partial.exact_mismatches(except: :secret)[:missing]).to eq([])
      expect(partial.exact_mismatches(except: :email)).to include(missing: ["secret"], labels: {})
      expect(partial.exact_mismatches(except: :email)[:unexpected]).not_to include("email")
      expect(form).to have_exact_fields(except: %i[notes orders])
      expect { form.has_exact_fields?(only: :secret) }.to raise_error(ArgumentError, /:secret is not declared/)
      expect { form.has_declared_fields?(except: [:secret]) }.to raise_error(ArgumentError, /:secret is not declared/)
      expect { form.exact_mismatches(except: :secret) }.to raise_error(ArgumentError, /:secret is not declared/)
    end

    it "builds the declared class" do
      form_page.load(action: "new")
      select_class = Class.new(ActiveAdminPageObjects::Form::SelectField)
      typed = declared_form do
        field :status, "Status", select_class
        field :website, "Website", ActiveAdminPageObjects::Form::DatePickerField
      end
      expect(typed.field(:status)).to be_an_instance_of(select_class)
      expect(typed.field(:website)).to be_an_instance_of(ActiveAdminPageObjects::Form::DatePickerField)
      expect(form.field(:signed_on)).to be_an_instance_of(ActiveAdminPageObjects::Form::DatePickerField)
    end

    it "raises when the page has a field of another class than the declared one" do
      form_page.load(action: "new")
      mistyped = declared_form do
        field :status, "Status", ActiveAdminPageObjects::Form::RadioField
        field :signed_on, "Signed on", ActiveAdminPageObjects::Form::StringField
        field :email, "Email", ActiveAdminPageObjects::Form::Field
      end
      expect { mistyped.field(:status) }.to raise_error(
        Capybara::ExpectationNotMet,
        ":status is declared as ActiveAdminPageObjects::Form::RadioField, " \
        "but the page has ActiveAdminPageObjects::Form::SelectField"
      )
      expect { mistyped.fill(status: "pending") }.to raise_error(Capybara::ExpectationNotMet, /RadioField/)
      expect do
        mistyped.field(:signed_on)
      end.to raise_error(Capybara::ExpectationNotMet, /StringField, but the page has .*DatePickerField/)
      expect { mistyped.field(:email) }.to raise_error(Capybara::ExpectationNotMet, /Form::Field, but the page has .*StringField/)
      expect(mistyped).to have_declared_fields
    end

    it "takes any key without declarations" do
      form_page.load(action: "new")
      lenient = described_class.new(form_page, form.root_element)
      expect(lenient).to have_no_field_error(:secret)
      expect(lenient.field(:name)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      expect(lenient.has_many(:orders)).to be_an_instance_of(ActiveAdminPageObjects::HasMany)
      expect { lenient.has_declared_fields? }.to raise_error(ArgumentError, /declares no labels/)
      expect { lenient.has_exact_fields? }.to raise_error(ArgumentError, /declares no labels/)
      expect { lenient.exact_mismatches }.to raise_error(ArgumentError, /declares no labels/)
    end

    describe "typed fields" do
      before { form_page.load(action: "new") }

      it "returns a StringField for the text inputs" do
        %i[name email external_id balance notes website phone password].each do |name|
          expect(form.field(name)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
        end
        form.field(:name).fill("Acme")
        expect(form.field(:name).value).to eq("Acme")
        form.fill(notes: "Big account")
        expect(form.field(:notes).value).to eq("Big account")
      end

      it "returns a SelectField for a select" do
        status = form.field(:status)
        expect(status).to be_an_instance_of(ActiveAdminPageObjects::Form::SelectField)
        expect(status.options).to eq(%w[active pending closed])
        expect(status.selected).to be_nil
        status.fill("pending")
        expect(status.selected).to eq("pending")
        status.choose("closed")
        expect(status.selected).to eq("closed")
      end

      it "returns a BooleanField for a boolean" do
        active = form.field(:active)
        expect(active).to be_an_instance_of(ActiveAdminPageObjects::Form::BooleanField)
        expect(active).to be_checked
        active.fill(false)
        expect(active).not_to be_checked
        active.fill(true)
        expect(active).to be_checked
      end

      it "returns a RadioField for a radio" do
        tier = form.field(:tier)
        expect(tier).to be_an_instance_of(ActiveAdminPageObjects::Form::RadioField)
        expect(tier.options).to eq(%w[Bronze Silver Gold])
        expect(tier.selected).to be_nil
        tier.fill("Gold")
        expect(tier.selected).to eq("Gold")
        tier.choose("Silver")
        expect(tier.selected).to eq("Silver")
      end

      it "returns a CheckBoxesField for check_boxes" do
        channels = form.field(:channels)
        expect(channels).to be_an_instance_of(ActiveAdminPageObjects::Form::CheckBoxesField)
        expect(channels.checked).to eq([])
        channels.check("Email", "Post")
        expect(channels.checked).to eq(%w[Email Post])
        channels.uncheck("Email")
        expect(channels.checked).to eq(["Post"])
        channels.fill(%w[Email Phone])
        expect(channels.checked).to eq(%w[Email Phone])
        channels.fill([])
        expect(channels.checked).to eq([])
      end

      it "returns a DatePickerField for a datepicker" do
        signed_on = form.field(:signed_on)
        expect(signed_on).to be_an_instance_of(ActiveAdminPageObjects::Form::DatePickerField)
        signed_on.fill("2026-01-31")
        expect(signed_on.value).to eq("2026-01-31")
        form.fill(signed_on: Date.new(2026, 2, 28))
        expect(signed_on.value).to eq("2026-02-28")
      end

      it "saves what the typed fields set" do
        form.fill(name: "Acme", email: "acme@example.com", website: "https://acme.example.com",
                  phone: "+1 555 0100", tier: "Gold", channels: %w[Email Post], signed_on: "2026-01-31")
        form.submit

        expect(form_page.flashes).to have_flash(:notice, "Customer was successfully created.")
        expect(Customer.last).to have_attributes(website: "https://acme.example.com", phone: "+1 555 0100", tier: "Gold",
                                                 channels: %w[Email Post], signed_on: Date.new(2026, 1, 31))
      end
    end

    describe "declared has_many blocks" do
      before { form_page.load(action: "new") }

      it "returns the declared has_many by its name" do
        expect(form.has_many(:orders).class).to be < ActiveAdminPageObjects::HasMany
        expect(form.has_many(:orders).heading).to eq("Orders")
        expect { form.has_many(:tags) }.to raise_error(ArgumentError, /:tags is not declared; declared keys: orders/)
        expect { form.field(:orders) }.to raise_error(ArgumentError, /:orders is declared as a has_many, not as a field/)
        expect { form.has_field_error?(:orders) }.to raise_error(ArgumentError, /has_many/)
      end

      it "compares the heading with the label matchers" do
        relabeled = declared_form { has_many :orders, "Order list" }
        expect(relabeled).to have_no_declared_fields
        expect(relabeled.declared_label_mismatches).to eq("orders" => "Orders")
        expect(relabeled.exact_mismatches[:unexpected]).not_to include("orders")
        expect(declared_form { has_many :orders, nil }.declared_label_mismatches).to eq("orders" => "Orders")
        expect(declared_form { has_many :tags, "Tags" }.exact_mismatches).to include(missing: ["tags"])
        expect(declared_form { has_many :tags, nil }.declared_label_mismatches).to eq("tags" => nil)
      end

      it "takes an undeclared has_many when the form declares none" do
        fields_only = declared_form { field :email, "Email", ActiveAdminPageObjects::Form::StringField }
        expect(fields_only.has_many(:orders)).to be_an_instance_of(ActiveAdminPageObjects::HasMany)
        expect(fields_only.exact_mismatches[:unexpected]).to include("orders")
      end
    end
  end

  it_behaves_like "resource form"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "resource form"
  end

  it "matches a has_many without a heading when nil is declared" do
    form_page.load(action: "new")
    page.execute_script("document.querySelector('.has_many_container.orders > h3').remove()")
    expect(declared_form { has_many :orders, nil }).to have_declared_fields
    expect(declared_form { has_many :orders, "Orders" }.declared_label_mismatches).to eq("orders" => "")
  end

  describe "declared fields" do
    let(:strict_class) do
      Class.new(described_class) do
        field :email, "Email", ActiveAdminPageObjects::Form::StringField
        field :external_id, "External ID", ActiveAdminPageObjects::Form::StringField
      end
    end

    it "rejects an undeclared name before it queries the page" do
      strict = strict_class.new(nil, nil)
      message = /:name is not declared; declared keys: email, external_id/
      expect { strict.field(:name) }.to raise_error(ArgumentError, message)
      expect { strict.fill(name: "Acme") }.to raise_error(ArgumentError, message)
      expect { strict.has_field_error?(:name) }.to raise_error(ArgumentError, message)
      expect { strict.has_no_field_error?(:name) }.to raise_error(ArgumentError, message)
      expect { strict.has_exact_field_errors?(name: "can't be blank") }.to raise_error(ArgumentError, message)
      expect { strict.has_no_exact_field_errors?(name: "can't be blank") }.to raise_error(ArgumentError, message)
      expect { strict.has_declared_fields?(only: :name) }.to raise_error(ArgumentError, message)
      expect { strict.has_exact_fields?(except: :name) }.to raise_error(ArgumentError, message)
    end

    it "takes a declared name as a symbol, a string or a label" do
      form_page.load(action: "new")
      strict = strict_class.new(form_page, form.root_element)
      strict.field(:external_id).fill("X-1")
      expect(strict.field("external_id").value).to eq("X-1")
      expect(strict.field("External ID").value).to eq("X-1")
    end

    it "requires a label and a section class" do
      expect { Class.new(described_class) { field :email } }.to raise_error(ArgumentError)
      expect { Class.new(described_class) { field :email, "Email" } }.to raise_error(ArgumentError)
      expect { Class.new(described_class) { field :email, "Email", nil } }
        .to raise_error(ArgumentError, "`field :email` needs a section class, got nil")
    end

    it "declares names that are methods of the section and reaches them with field" do
      form_page.load(action: "new")
      named = declared_form do
        field :name, "Name", ActiveAdminPageObjects::Form::StringField
        field :title, "Title", ActiveAdminPageObjects::Form::StringField
      end
      expect(named.class.declarations.keys).to eq(%w[name title])
      expect(named.field(:name)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
      named.field(:name).fill("Acme")
      expect(named.field(:name).value).to eq("Acme")
    end

    it "lets a subclass declare an inherited name again" do
      select_class = Class.new(ActiveAdminPageObjects::Form::SelectField)
      subclass = Class.new(strict_class) { field :email, "E-mail", select_class }
      expect(subclass.declarations["email"]).to eq(label: "E-mail", type: select_class, kind: :field)
      expect(strict_class.declarations["email"][:label]).to eq("Email")
    end

    it "inherits declarations and leaves the superclass unchanged" do
      subclass = Class.new(strict_class) { field :status, "Status", ActiveAdminPageObjects::Form::SelectField }
      expect(subclass.declarations.keys).to eq(%w[email external_id status])
      expect(subclass.declarations["email"])
        .to eq(label: "Email", type: ActiveAdminPageObjects::Form::StringField, kind: :field)
      expect(strict_class.declarations.keys).to eq(%w[email external_id])
      expect(described_class.declarations).to be_empty
    end
  end

  describe ".register_type" do
    it "registers a section for another input class" do
      custom = Class.new(described_class::Field)
      described_class.register_type("datepicker", custom)
      form_page.load(action: "new")
      expect(described_class.new(form_page, form.root_element).field(:signed_on)).to be_a(custom)
    ensure
      described_class.register_type("datepicker", described_class::DatePickerField)
    end
  end
end
