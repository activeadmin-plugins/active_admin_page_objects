# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Selectors do
  around do |example|
    saved = described_class::MAP.dup
    example.run
  ensure
    described_class::MAP.replace(saved)
  end

  it "reads the map and fills placeholders" do
    expect(ActiveAdminPageObjects.selector(:table)).to eq("table.index_table")
    expect(ActiveAdminPageObjects.selector(:filter, "name")).to eq("#q_name_input")
    expect(ActiveAdminPageObjects.selector(:form_input, "customer", "name")).to eq("li#customer_name_input")
  end

  it "raises for a key ActiveAdmin 3 lacks" do
    expect { ActiveAdminPageObjects.selector(:dark_mode_toggle) }
      .to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3, /dark mode toggle is not in ActiveAdmin 3/)
    expect { ActiveAdminPageObjects.selector(:user_menu_button) }
      .to raise_error(ActiveAdminPageObjects::NotInActiveAdmin3, /user menu button is not in ActiveAdmin 3/)
  end

  it "has a selector for the components ActiveAdmin 4 removed" do
    expect(described_class::DEFAULTS.values_at(:tabs, :utility_navigation, :action_item_dropdown)).to all(be_a(String))
  end

  it "raises KeyError for an unknown key" do
    expect { ActiveAdminPageObjects.selector(:nope) }.to raise_error(KeyError, /no selector for :nope/)
  end

  describe ".register_selectors" do
    it "overrides an entry" do
      ActiveAdminPageObjects.register_selectors(table: "table.themed")
      expect(ActiveAdminPageObjects.selector(:table)).to eq("table.themed")
    end

    it "replaces an entry ActiveAdmin 3 lacks" do
      ActiveAdminPageObjects.register_selectors(dark_mode_toggle: ".my-toggle")
      expect(ActiveAdminPageObjects.selector(:dark_mode_toggle)).to eq(".my-toggle")
    end

    it "leaves the defaults untouched" do
      ActiveAdminPageObjects.register_selectors(table: "table.themed")
      expect(described_class::DEFAULTS[:table]).to eq("table.index_table")
    end
  end
end
