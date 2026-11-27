# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Section do
  let(:show) { Pages::CustomerShow.new }

  before { show.load(id: create_customer.id) }

  # Capybara's synchronize builds its timer from `false` and fails on the second try.
  it "takes wait: false as no wait in the predicates that retry" do
    expect(show.tabs.has_tab?("Missing", wait: false)).to be(false)
    expect(show.tabs.has_no_tab?("Overview", wait: false)).to be(false)
    expect(show.tabs.has_tab?("Overview", wait: false)).to be(true)
    expect(show.attributes_table.has_exact_rows?(only: :name, wait: false)).to be(true)
    expect(show.attributes_table.has_no_exact_rows?(only: :name, wait: false)).to be(false)
  end

  it "keeps the text helpers private" do
    expect(show.tabs).not_to respond_to(:squish)
    expect(show.tabs).not_to respond_to(:slug)
    expect(show.tabs.send(:slug, "External ID")).to eq("external_id")
  end
end
