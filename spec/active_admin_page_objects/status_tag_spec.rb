# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::StatusTag do
  let(:index) { Pages::CustomerIndex.new }
  let(:show) { Pages::CustomerShow.new }
  let!(:customer) { create_customer(status: "pending", active: false) }
  let(:row) { index.table.row(customer.id) }

  shared_examples "status tags" do
    describe "in an index row" do
      before { index.load }

      it "reads a tag's label and status" do
        tag = row.status_tag(:status)
        expect(tag).to be_a(described_class)
        expect(tag.label).to eq("Pending")
        expect(tag.status).to eq("pending")
        expect(row.status_tag(:active).status).to eq("no")
        expect(row.status_tag(:active).label).to eq("No")
      end

      it "compares a tag's status and label" do
        tag = row.status_tag(:status)
        expect(tag).to have_status(:pending)
        expect(tag).to have_status("pending")
        expect(tag).to have_no_status(:active)
        expect(tag).to have_label("PENDING")
        expect(tag).to have_no_label("Pend")
        expect(tag.has_status?(:active, wait: 0)).to be(false)
        expect(tag.has_no_status?(:pending, wait: 0)).to be(false)
        expect(row.status_tag(:active)).to have_status(false)
        expect { tag.has_status?(1) }.to raise_error(ArgumentError, /status must be a String, a Symbol/)
      end

      it "has a status tag by label, status or both" do
        expect(row).to have_status_tag(:status)
        expect(row).to have_status_tag(:status, "Pending")
        expect(row).to have_status_tag(:status, "PENDING")
        expect(row).to have_status_tag("Status", /Pend/)
        expect(row).to have_status_tag(:status, status: :pending)
        expect(row).to have_status_tag(:status, "pending", status: "pending")
        expect(row).to have_status_tag(:status, type: :pending)
        expect(row).to have_status_tag(:active, "No", status: false)
        expect(row).to have_status_tag(:active, status: :no)
      end

      it "has no status tag when the label or the status differs" do
        expect(row).to have_no_status_tag(:status, "Pend")
        expect(row).to have_no_status_tag(:status, "Active")
        expect(row).to have_no_status_tag(:status, status: :active)
        expect(row).to have_no_status_tag(:status, type: :active)
        expect(row).to have_no_status_tag(:status, "Pending", status: :active)
        expect(row).to have_no_status_tag(:active, status: true)
        expect(row).to have_no_status_tag(:name)
      end

      it "does not wait for a tag that is there, or give a false pass" do
        expect(row.has_status_tag?(:status, "Active", wait: 0)).to be(false)
        expect(row.has_status_tag?(:status, status: :active, wait: 0)).to be(false)
        expect(row.has_no_status_tag?(:status, "Pending", wait: 0)).to be(false)
        expect(row.has_no_status_tag?(:status, status: :pending, wait: 0)).to be(false)
      end

      it "passes Capybara options on" do
        expect(row).to have_status_tag(:status, count: 1)
        expect(row).to have_no_status_tag(:status, count: 2)
      end

      it "rejects a call that would match nothing" do
        expect { row.has_status_tag?(:status, status: :pending, type: :pending) }
          .to raise_error(ArgumentError, /status: or type:, not both/)
        expect { row.has_no_status_tag?(:status, status: :pending, type: :active) }
          .to raise_error(ArgumentError, /status: or type:, not both/)
        expect { row.has_no_status_tag?(:status, status: 1) }.to raise_error(ArgumentError, /status must be a String/)
        expect { row.has_no_status_tag?(:status, type: Object.new) }.to raise_error(ArgumentError, /status must be a String/)
        expect { row.has_status_tag?(:secret) }.to raise_error(ArgumentError, /:secret is not declared/)
        expect { row.status_tag(:secret) }.to raise_error(ArgumentError, /:secret is not declared/)
      end

      it "finds no tag in a cell without one" do
        expect { row.status_tag(:name) }.to raise_error(Capybara::ElementNotFound)
        expect(row.status_tags(:name)).to eq([])
      end
    end

    describe "in a cell with several tags" do
      let(:lenient_row) do
        ActiveAdminPageObjects::Table.new(index, index.table.root_element).row(customer.id)
      end

      before { index.load(query: { with_flags: 1 }) }

      it "lists the tags in page order" do
        tags = lenient_row.status_tags(:flags)
        expect(tags.map(&:status)).to eq(%w[pending no])
        expect(tags.map(&:label)).to eq(%w[Pending No])
      end

      it "is ambiguous for one tag, and has a tag when any matches" do
        expect { lenient_row.status_tag(:flags) }.to raise_error(Capybara::Ambiguous)
        expect(lenient_row).to have_status_tag(:flags, "No")
        expect(lenient_row).to have_status_tag(:flags, status: :pending)
        expect(lenient_row).to have_status_tag(:flags, count: 2)
        expect(lenient_row).to have_no_status_tag(:flags, "Active")
      end
    end

    describe "on a show page" do
      before { show.load(id: customer.id) }

      it "reads and compares the tag of a row" do
        tag = show.attributes_table.status_tag(:status)
        expect(tag.label).to eq("Pending")
        expect(tag.status).to eq("pending")
        expect(show.attributes_table.status_tags(:status).size).to eq(1)
        expect(show.attributes_table).to have_status_tag(:status, "pending", status: :pending)
        expect(show.attributes_table).to have_status_tag("Status", type: "pending")
        expect(show.attributes_table).to have_no_status_tag(:status, "Active")
        expect(show.attributes_table).to have_no_status_tag(:status, status: :active)
        expect(show.attributes_table).to have_no_status_tag(:name)
        expect { show.attributes_table.has_status_tag?(:secret) }.to raise_error(ArgumentError, /:secret is not declared/)
        expect { show.attributes_table.has_status_tag?(:status, status: :a, type: :b) }.to raise_error(ArgumentError)
      end
    end
  end

  it_behaves_like "status tags"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "status tags"
  end
end
