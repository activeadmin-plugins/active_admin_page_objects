# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Text do
  it "matches a regexp against the squished text, and any other value as the same text" do
    expect(ActiveAdminPageObjects.text_match?(" Possible\n Routes (2) ", /\APossible Routes \(\d+\)\z/)).to be(true)
    expect(ActiveAdminPageObjects.text_match?("Possible Routes (2)", /\ARoutes/)).to be(false)
    expect(ActiveAdminPageObjects.text_match?("ROUTES ", "Routes")).to be(true)
    expect(ActiveAdminPageObjects.text_match?("Routes (2)", "Routes")).to be(false)
  end

  it "normalizes whitespace and case" do
    expect(ActiveAdminPageObjects.normalize_text("  EXTERNAL\n  Id ")).to eq("external id")
    expect(ActiveAdminPageObjects.same_text?("CREATED AT", "Created at")).to be(true)
    expect(ActiveAdminPageObjects.same_text?("Created", "Created at")).to be(false)
  end

  it "squishes whitespace and keeps the case" do
    expect(ActiveAdminPageObjects.squish("  External\n  ID ")).to eq("External ID")
  end

  it "slugs keys the way ActiveAdmin writes the col- and row- classes" do
    expect(ActiveAdminPageObjects.slug("EXTERNAL ID")).to eq("external_id")
    expect(ActiveAdminPageObjects.slug(:external_id)).to eq("external_id")
    expect(ActiveAdminPageObjects.slug("Signed up")).to eq("signed_up")
  end

  it "slugs a key whose text has no parameterize, as without ActiveSupport" do
    plain = +" External ID (new) "
    plain.singleton_class.undef_method(:parameterize)
    key = Object.new
    key.define_singleton_method(:to_s) { plain }
    expect(ActiveAdminPageObjects.slug(key)).to eq("external_id_new")
  end

  it "formats a date for the date inputs" do
    expect(ActiveAdminPageObjects.iso_date(Date.new(2026, 1, 31))).to eq("2026-01-31")
    expect(ActiveAdminPageObjects.iso_date(Time.utc(2026, 1, 31, 12))).to eq("2026-01-31")
    expect(ActiveAdminPageObjects.iso_date("2026-01-31")).to eq("2026-01-31")
    expect(ActiveAdminPageObjects.iso_date(nil)).to eq("")
  end
end

RSpec.describe ActiveAdminPageObjects do
  describe ".check_version!" do
    it "passes for a satisfied requirement" do
      expect { described_class.check_version!(">= 1.0.0.a", "< 2.0.0.a", plugin: "demo") }.not_to raise_error
    end

    it "keeps the 2.x prereleases out with an upper bound of 2.0.0.a" do
      stub_const("ActiveAdminPageObjects::VERSION", "2.0.0.alpha")
      expect { described_class.check_version!(">= 1.0.0.a", "< 2.0.0.a", plugin: "demo") }
        .to raise_error(ActiveAdminPageObjects::IncompatibleVersion)
    end

    it "raises for an unsatisfied requirement" do
      expect { described_class.check_version!(">= 2.0", plugin: "demo") }
        .to raise_error(ActiveAdminPageObjects::IncompatibleVersion, /demo page objects need active_admin_page_objects >= 2.0/)
    end
  end

  it "has a version" do
    expect(ActiveAdminPageObjects::VERSION).to eq("1.0.0.alpha")
  end
end
