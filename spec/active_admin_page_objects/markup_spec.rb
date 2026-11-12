# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Markup do
  after { ActiveAdminPageObjects.markup = nil }

  describe ".markup" do
    it "detects stock ActiveAdmin 4" do
      expect(ActiveAdminPageObjects.markup).to eq(:v4)
    end

    it "detects ActiveAdmin 3" do
      stub_const("ActiveAdmin::VERSION", "3.5.2")
      expect(ActiveAdminPageObjects.detect_markup).to eq(:v3)
    end

    it "detects theme v4 on ActiveAdmin 4" do
      stub_const("ActiveAdminTheme::VERSION", "4.0.0")
      expect(ActiveAdminPageObjects.detect_markup).to eq(:theme_v4)
    end

    it "keeps stock markup with an older theme" do
      stub_const("ActiveAdminTheme::VERSION", "3.3.0")
      expect(ActiveAdminPageObjects.detect_markup).to eq(:v4)
    end

    it "raises when ActiveAdmin is not loaded" do
      hide_const("ActiveAdmin")
      expect { ActiveAdminPageObjects.detect_markup }
        .to raise_error(ActiveAdminPageObjects::UnsupportedMarkup, /not loaded/)
    end

    it "can be set explicitly" do
      ActiveAdminPageObjects.markup = :theme_v4
      expect(ActiveAdminPageObjects.markup).to eq(:theme_v4)
      expect { ActiveAdminPageObjects.markup = :v5 }.to raise_error(ArgumentError, /markup must be one of/)
    end
  end

  describe ".selector" do
    it "reads the v4 map and fills placeholders" do
      expect(ActiveAdminPageObjects.selector(:table)).to eq("table.data-table")
      expect(ActiveAdminPageObjects.selector(:filter, "name")).to eq("#q_name_input")
    end

    it "falls back to v4 entries for theme v4" do
      ActiveAdminPageObjects.markup = :theme_v4
      expect(ActiveAdminPageObjects.selector(:table)).to eq("table.data-table")
    end

    it "raises for v3 markup" do
      ActiveAdminPageObjects.markup = :v3
      expect { ActiveAdminPageObjects.selector(:table) }
        .to raise_error(ActiveAdminPageObjects::UnsupportedMarkup, /ActiveAdmin 3 markup is not supported/)
    end

    it "raises for features removed in ActiveAdmin 4" do
      expect { ActiveAdminPageObjects.selector(:tabs) }
        .to raise_error(ActiveAdminPageObjects::RemovedInActiveAdmin4, "tabs was removed in ActiveAdmin 4")
    end

    it "raises for an unknown key" do
      expect { ActiveAdminPageObjects.selector(:nope) }.to raise_error(KeyError, /:nope/)
    end
  end

  describe ".register_selectors" do
    after { ActiveAdminPageObjects::Selectors::MAPS[:theme_v4].delete(:table) }

    it "overrides one entry for one markup" do
      ActiveAdminPageObjects.register_selectors(:theme_v4, table: "table.themed")
      ActiveAdminPageObjects.markup = :theme_v4
      expect(ActiveAdminPageObjects.selector(:table)).to eq("table.themed")
      ActiveAdminPageObjects.markup = :v4
      expect(ActiveAdminPageObjects.selector(:table)).to eq("table.data-table")
    end

    it "rejects an unknown markup" do
      expect { ActiveAdminPageObjects.register_selectors(:v9, table: "x") }.to raise_error(ArgumentError)
    end
  end
end
