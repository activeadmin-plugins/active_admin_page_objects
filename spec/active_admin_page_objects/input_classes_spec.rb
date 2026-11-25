# frozen_string_literal: true

RSpec.describe "registered field and filter classes" do
  let(:widget_field) { Class.new(ActiveAdminPageObjects::Form::SelectField) }
  let(:widget_filter) { Class.new(ActiveAdminPageObjects::SelectFilter) }

  around do |example|
    saved = [ActiveAdminPageObjects::InputClasses.fields.dup, ActiveAdminPageObjects::InputClasses.filters.dup]
    example.run
  ensure
    ActiveAdminPageObjects::InputClasses.fields.replace(saved[0])
    ActiveAdminPageObjects::InputClasses.filters.replace(saved[1])
  end

  # A plugin input renders its own formtastic class next to the class of the
  # input it extends, as `searchable_select select input` here.
  def mark_widget(wrapper_id)
    page.execute_script("document.querySelector('##{wrapper_id}').classList.add('searchable_select')")
  end

  describe ".register_field_class" do
    let(:form_page) { Pages::CustomerForm.new }
    # Undeclared, so lookups return the detected class.
    let(:form) { ActiveAdminPageObjects::Form.new(form_page, form_page.form.root_element) }

    before { create_category("Retail") }

    it "returns the registered class for its wrapper class, ahead of the gem's class" do
      ActiveAdminPageObjects.register_field_class("searchable_select", widget_field)
      form_page.load(action: "new")
      mark_widget("customer_status_input")

      expect(form.field(:status)).to be_an_instance_of(widget_field)
      expect(form.field(:name)).to be_an_instance_of(ActiveAdminPageObjects::Form::StringField)
    end

    it "replaces the gem's class for the same wrapper class" do
      ActiveAdminPageObjects.register_field_class(:select, widget_field)
      form_page.load(action: "new")

      expect(form.field(:status)).to be_an_instance_of(widget_field)
    end

    it "raises when a page object declares the gem's class for a registered input" do
      ActiveAdminPageObjects.register_field_class("searchable_select", widget_field)
      form_page.load(action: "new")
      mark_widget("customer_status_input")

      expect { form_page.form.field(:status) }.to raise_error(ActiveAdminPageObjects::DeclaredClassMismatch)
    end

    it "accepts a declared subclass of the registered class and rejects the gem's class" do
      ActiveAdminPageObjects.register_field_class("searchable_select", widget_field)
      subclass = Class.new(widget_field)
      form_class = Class.new(ActiveAdminPageObjects::Form) do
        field :status, "Status", subclass
        field :category, "Category", ActiveAdminPageObjects::Form::SelectField
      end
      form_page.load(action: "new")
      mark_widget("customer_status_input")
      mark_widget("customer_category_input")
      declared = form_class.new(form_page, form_page.form.root_element)

      expect(declared.field(:status)).to be_an_instance_of(subclass)
      expect { declared.field(:category) }.to raise_error(ActiveAdminPageObjects::DeclaredClassMismatch)
    end

    it "takes only a Form::Field subclass" do
      expect { ActiveAdminPageObjects.register_field_class("widget", widget_filter) }
        .to raise_error(ArgumentError, /not a subclass of ActiveAdminPageObjects::Form::Field/)
      expect { ActiveAdminPageObjects.register_field_class("widget", "SelectField") }.to raise_error(ArgumentError)
    end
  end

  describe ".register_filter_class" do
    let(:index) { Pages::CustomerIndex.new }
    let(:filters) { ActiveAdminPageObjects::Filters.new(index, index.filters.root_element) }

    it "returns the registered class for its wrapper class, ahead of the gem's class" do
      ActiveAdminPageObjects.register_filter_class("searchable_select", widget_filter)
      index.load
      mark_widget("q_status_input")

      expect(filters.filter(:status)).to be_an_instance_of(widget_filter)
      expect(filters.filter(:name)).to be_an_instance_of(ActiveAdminPageObjects::StringFilter)
    end

    it "takes only a Filter subclass" do
      expect { ActiveAdminPageObjects.register_filter_class("widget", widget_field) }
        .to raise_error(ArgumentError, /not a subclass of ActiveAdminPageObjects::Filter/)
    end
  end
end
