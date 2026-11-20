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
    expect(described_class.public_instance_methods).to match_array(described_class::NAMES)
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
end
