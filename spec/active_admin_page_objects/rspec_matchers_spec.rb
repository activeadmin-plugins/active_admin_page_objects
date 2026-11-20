# frozen_string_literal: true

require "active_admin_page_objects/rspec"

# Stands in for capybara_active_admin: matchers of the same names, written for Capybara's `page`.
module OtherLibraryMatchers
  def have_page_title(text, options = {})
    have_css("[data-test-page-header] h2", text: text, **options)
  end

  def have_table(options = {})
    have_css("table.data-table", **options)
  end

  def have_semantic_errors(options = {})
    have_css("ul.errors > li", **options)
  end

  def have_status_tag(type, **options)
    have_css("span.status-tag[data-status='#{type}']", **options)
  end

  def have_flash_message(text, options = {})
    satisfy("show the flash #{text}") { |actual| actual.has_css?("[data-test-page-header] + div div", text: text, **options) }
  end
end

RSpec.describe ActiveAdminPageObjects::RSpec::Matchers do
  let(:index) { Pages::CustomerIndex.new }
  let(:form_page) { Pages::CustomerForm.new }

  before { create_customer(active: false) }

  def submit_reserved_name
    form_page.load(action: "new")
    form_page.form.fill_fields(customer_name: "Reserved", email: "acme@example.com")
    form_page.form.submit
  end

  it "names every matcher of capybara_active_admin 1.0.0" do
    expect(described_class::NAMES.size).to eq(24)
    expect(described_class.public_instance_methods).to match_array(described_class::NAMES)
  end

  context "when included after the other library" do
    include OtherLibraryMatchers
    include ActiveAdminPageObjects::RSpec::Matchers

    before { index.load }

    it "asks a page object its predicate" do
      expect(index).to have_page_title(text: "Customers")
      expect(index).to have_table
      submit_reserved_name
      expect(form_page.form).to have_semantic_errors("Name is reserved")
    end

    it "asks a page object its has_no predicate when negated" do
      submit_reserved_name
      form = form_page.form
      allow(form).to receive(:has_no_semantic_errors?).and_call_original
      expect(form).not_to have_semantic_errors("Email is taken")
      expect(form).to have_received(:has_no_semantic_errors?).with("Email is taken")
      tags = Pages::TagIndex.new
      tags.load
      expect(tags).not_to have_table
    end

    it "negates the predicate of a page object without a has_no predicate" do
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
      expect(page).to have_status_tag(:no, text: /no/i)
      expect(page).not_to have_status_tag(:yes)
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
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected to find .*data-test-page-header/)
      expect { expect(page).not_to have_page_title("Customers", wait: 0) }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected not to find .*data-test-page-header/)
      # Ruby 3.3 and 3.4 inspect the options hash differently.
      expect(have_page_title(text: "Customers").description).to match(/\Ahave page title \{.*"Customers"\}\z/)
    end
  end

  context "when no other library defines the matcher" do
    include ActiveAdminPageObjects::RSpec::Matchers

    before { index.load }

    it "is the predicate matcher for any object" do
      expect(index).to have_page_title(text: "Customers")
      expect(index).not_to have_page_title(text: "Orders")
      expect { expect(page).to have_footer }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /to respond to `has_footer\?`/)
    end

    it "uses a matcher of the same name that Capybara or SitePrism defines" do
      expect(page).to have_table(count: 1)
      expect(page).not_to have_table("Orders", wait: 0)
      expect(index).to have_table
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
