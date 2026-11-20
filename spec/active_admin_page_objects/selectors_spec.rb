# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Selectors do
  around do |example|
    saved = described_class::MAP.dup
    example.run
  ensure
    described_class::MAP.replace(saved)
  end

  it "reads the map and fills placeholders" do
    expect(ActiveAdminPageObjects.selector(:table)).to eq("table.data-table")
    expect(ActiveAdminPageObjects.selector(:filter, "name")).to eq("#q_name_input")
  end

  it "raises for a key ActiveAdmin 4 removed" do
    expect { ActiveAdminPageObjects.selector(:tabs) }
      .to raise_error(ActiveAdminPageObjects::RemovedInActiveAdmin4, /tabs was removed in ActiveAdmin 4/)
  end

  it "raises KeyError for an unknown key" do
    expect { ActiveAdminPageObjects.selector(:nope) }.to raise_error(KeyError, /no selector for :nope/)
  end

  describe ".register_selectors" do
    it "overrides an entry" do
      ActiveAdminPageObjects.register_selectors(table: "table.themed")
      expect(ActiveAdminPageObjects.selector(:table)).to eq("table.themed")
    end

    it "replaces a removed key" do
      ActiveAdminPageObjects.register_selectors(tabs: ".my-tabs")
      expect(ActiveAdminPageObjects.selector(:tabs)).to eq(".my-tabs")
    end

    it "leaves the defaults untouched" do
      ActiveAdminPageObjects.register_selectors(table: "table.themed")
      expect(described_class::DEFAULTS[:table]).to eq("table.data-table")
    end
  end
end
