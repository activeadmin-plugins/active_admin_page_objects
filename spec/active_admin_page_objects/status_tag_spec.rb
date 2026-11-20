# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::StatusTag do
  let!(:customer) { create_customer(status: "pending") }

  shared_examples "a pending tag" do
    it "reads the label and type" do
      expect(tag.label).to eq("Pending")
      expect(tag.type).to eq("pending")
    end

    it "matches the type and the label" do
      expect(tag).to have_type("pending")
      expect(tag).to have_no_type("active", wait: 0)
      expect(tag).to have_label("pending")
      expect(tag).to have_label("PENDING")
      expect(tag).to have_no_label("Active", wait: 0)
    end

    it "matches the label and the type at once" do
      expect(tag.match?("PENDING")).to be(true)
      expect(tag.match?("Pending", type: "pending")).to be(true)
      expect(tag.match?("Pending", type: "active")).to be(false)
      expect(tag.match?("Active", type: "pending")).to be(false)
    end
  end

  context "in an index row" do
    let(:tag) do
      index = Pages::CustomerIndex.new
      index.load
      index.table.row(customer.id).status_tag(:status)
    end

    it_behaves_like "a pending tag"
  end

  context "in the show attributes" do
    let(:tag) do
      show = Pages::CustomerShow.new
      show.load(id: customer.id)
      show.attributes_table.status_tag(:status)
    end

    it_behaves_like "a pending tag"
  end
end
