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

  shared_examples "two tags in a cell" do
    it "matches any status tag of the cell" do
      expect(cells).to have_status_tag(:flags, "Draft")
      expect(cells).to have_status_tag(:flags, "archived", type: "warning")
      expect(cells).to have_status_tag(:flags, "Archived", type: "archived warning")
      expect(cells).to have_no_status_tag(:flags, "Published")
      expect(cells).to have_no_status_tag(:flags, "Draft", type: "warning")
      Capybara.using_wait_time(0) do
        expect(cells.has_status_tag?(:flags, "Published")).to be(false)
        expect(cells.has_no_status_tag?(:flags, "Draft")).to be(false)
        expect(cells.has_no_status_tag?(:flags, "Archived")).to be(false)
      end
    end

    it "lists the status tags of the cell" do
      expect(cells.status_tags(:flags).map(&:label)).to eq(%w[Draft Archived])
      expect(cells.status_tags(:flags).map(&:type)).to eq(["draft", "archived warning"])
      expect(cells.status_tags(:name)).to eq([])
      expect { cells.status_tag(:flags) }.to raise_error(Capybara::Ambiguous)
    end
  end

  context "with two tags in an index cell" do
    let(:cells) do
      document = create_document(archived: true)
      index = Pages::DocumentIndex.new
      index.load
      index.table.row(document.id)
    end

    it_behaves_like "two tags in a cell"

    context "with rack_test", driver: :rack_test do
      it_behaves_like "two tags in a cell"
    end
  end

  context "with two tags in a show row" do
    let(:cells) do
      show = Pages::DocumentShow.new
      show.load(id: create_document(archived: true).id)
      show.attributes_table
    end

    it_behaves_like "two tags in a cell"
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
