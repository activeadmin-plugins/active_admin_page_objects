# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Text do
  it "normalizes whitespace and case" do
    expect(ActiveAdminPageObjects.normalize_text("  EXTERNAL\n  Id ")).to eq("external id")
    expect(ActiveAdminPageObjects.same_text?("CREATED AT", "Created at")).to be(true)
    expect(ActiveAdminPageObjects.same_text?("Created", "Created at")).to be(false)
  end

  it "squishes whitespace and keeps the case" do
    expect(ActiveAdminPageObjects.squish("  External\n  ID ")).to eq("External ID")
  end

  it "slugs keys the way ActiveAdmin writes data-column" do
    expect(ActiveAdminPageObjects.slug("EXTERNAL ID")).to eq("external_id")
    expect(ActiveAdminPageObjects.slug(:external_id)).to eq("external_id")
    expect(ActiveAdminPageObjects.slug("Signed up")).to eq("signed_up")
  end
end

RSpec.describe ActiveAdminPageObjects do
  describe ".check_version!" do
    it "passes for a satisfied requirement" do
      expect { described_class.check_version!(">= 2.0.0.a", "< 3", plugin: "demo") }.not_to raise_error
    end

    it "raises for an unsatisfied requirement" do
      expect { described_class.check_version!(">= 3.0", plugin: "demo") }
        .to raise_error(ActiveAdminPageObjects::IncompatibleVersion, /demo page objects need active_admin_page_objects >= 3.0/)
    end
  end

  it "has a version" do
    expect(ActiveAdminPageObjects::VERSION).to eq("2.0.0.alpha")
  end
end
