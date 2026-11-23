# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Fields, "disabled fields" do
  let(:form_page) { Pages::DocumentForm.new }
  let(:form) { form_page.form }

  shared_examples "disabled fields" do
    before { form_page.load(action: "new") }

    it "tells whether a field of any type is disabled" do
      %i[code state kind archived].each do |name|
        expect(form.field(name)).to be_disabled
        expect(form.field(name)).not_to be_enabled
      end
      %i[name attachment].each do |name|
        expect(form.field(name)).to be_enabled
        expect(form.field(name)).not_to be_disabled
      end
    end

    it "matches the disabled and the enabled fields of a form" do
      expect(form).to have_disabled_field(:code)
      expect(form).to have_disabled_field(:state)
      expect(form).to have_disabled_field(:kind)
      expect(form).to have_disabled_field("Archived")
      expect(form).to have_no_enabled_field(:code)
      expect(form).to have_enabled_field(:name)
      expect(form).to have_enabled_field(:attachment)
      expect(form).to have_no_disabled_field(:name)
      Capybara.using_wait_time(0) do
        expect(form.has_disabled_field?(:name)).to be(false)
        expect(form.has_no_disabled_field?(:code)).to be(false)
        expect(form.has_enabled_field?(:code)).to be(false)
        expect(form.has_no_enabled_field?(:name)).to be(false)
      end
      expect(form.has_enabled_field?(:kind, wait: 0)).to be(false)
    end

    it "asks the declared class of the field" do
      never = Class.new(ActiveAdminPageObjects::Form::StringField) { def disabled? = false }
      declared = Class.new(ActiveAdminPageObjects::Form) { field :code, "Code", never }.new(form_page, form.root_element)
      expect(declared).to have_no_disabled_field(:code)
      expect(declared.has_disabled_field?(:code, wait: 0)).to be(false)
    end

    it "rejects an undeclared name before it queries the page" do
      message = /:secret is not declared/
      expect { form.has_disabled_field?(:secret) }.to raise_error(ArgumentError, message)
      expect { form.has_no_disabled_field?(:secret) }.to raise_error(ArgumentError, message)
      expect { form.has_enabled_field?(:secret) }.to raise_error(ArgumentError, message)
      expect { form.has_no_enabled_field?(:secret) }.to raise_error(ArgumentError, message)
    end

    it "takes a field that is not on the page for neither" do
      plain = ActiveAdminPageObjects::Form.new(form_page, form.root_element)
      expect(plain).to have_no_disabled_field(:secret)
      expect(plain).to have_no_enabled_field(:secret)
      expect(plain.has_disabled_field?(:secret, wait: 0)).to be(false)
      expect(plain.has_enabled_field?(:secret, wait: 0)).to be(false)
    end
  end

  it_behaves_like "disabled fields"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "disabled fields"
  end

  it "takes a field with one enabled choice for enabled" do
    form_page.load(action: "new")
    page.execute_script("document.querySelector('#document_kind_memo').disabled = false")
    expect(form).to have_enabled_field(:kind)
    expect(form).to have_no_disabled_field(:kind)
    expect(form.field(:kind)).to be_enabled
  end

  it "waits for a script to enable or disable the field" do
    form_page.load(action: "new")
    page.execute_script(<<~JS)
      setTimeout(() => {
        document.querySelector('#document_code').disabled = false
        document.querySelector('#document_name').disabled = true
      }, 300)
    JS
    expect(form).to have_enabled_field(:code)
    expect(form).to have_disabled_field(:name)
  end

  it "finds a hidden field with visible: :all" do
    form_page.load(action: "new")
    hide("#document_code_input")
    expect(form).to have_no_disabled_field(:code)
    expect(form).to have_disabled_field(:code, visible: :all)
    expect(form.has_disabled_field?(:code, wait: 0)).to be(false)
  end
end
