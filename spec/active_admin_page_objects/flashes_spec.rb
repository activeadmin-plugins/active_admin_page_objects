# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Flashes do
  let(:index) { Pages::CustomerIndex.new }

  before do
    index.load
    index.action_items.click("Report")
  end

  it "checks flashes by type and text" do
    expect(index.flashes).to have_flash(:alert, "Report is not ready")
    expect(index.flashes).to have_flash(:error, "Report failed")
    expect(index.flashes).to have_flash(:error)
    expect(index.flashes).to have_no_flash(:notice)
    expect(index.flashes).to have_no_flash(:warning)
    expect(index.flashes).to have_no_flash(:alert, "Report failed")
  end

  it "lists the messages" do
    expect(index.flashes.messages).to eq(["Report is not ready", "Report failed"])
    expect(index.flashes.messages(:error)).to eq(["Report failed"])
  end

  it "rejects a type outside TYPES" do
    expect { index.flashes.has_flash?(:info) }.to raise_error(ArgumentError, /flash type/)
    expect { index.flashes.has_flash?(nil) }.to raise_error(ArgumentError, /flash type must be one of .*got nil/)
    expect { index.flashes.has_no_flash?(nil) }.to raise_error(ArgumentError, /flash type/)
    expect { index.flashes.messages(42) }.to raise_error(ArgumentError, /got 42/)
  end

  it "finds no flash on a page without flashes" do
    index.load
    expect(index.flashes).to have_no_flash(:notice)
    expect(index.flashes.messages).to eq([])
  end
end
