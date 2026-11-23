# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::DownloadLinks do
  let(:index) { Pages::DocumentIndex.new }
  let(:links) { index.download_links }

  before do
    create_document
    index.load
  end

  shared_examples "download links" do
    it "lists the formats and reads their links" do
      expect(links.formats).to eq(%w[CSV XML JSON])
      expect(links).to have_format("CSV")
      expect(links).to have_format(:json)
      expect(links).to have_no_format("PDF")
      expect(links.href(:csv)).to eq("/admin/documents.csv")
      expect(links.href("JSON")).to eq("/admin/documents.json")
      expect(links.has_format?("PDF", wait: 0)).to be(false)
      expect(links.has_no_format?("CSV", wait: 0)).to be(false)
    end

    it "raises for a format without a link" do
      expect { links.href("PDF") }.to raise_error(Capybara::ElementNotFound, /"PDF" in \["CSV", "XML", "JSON"\]/)
      expect { links.click("PDF") }.to raise_error(Capybara::ElementNotFound)
    end
  end

  it_behaves_like "download links"

  it "clicks the link of a format" do
    links.click("JSON")
    expect(page).to have_current_path("/admin/documents.json")
    expect(page).to have_text('"name":"Contract"')
  end

  context "with rack_test", driver: :rack_test do
    it_behaves_like "download links"

    it "downloads the format it clicks" do
      links.click(:csv)
      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.body).to include("Contract")
    end
  end

  it "is absent on a blank slate" do
    Document.delete_all
    index.load
    expect(index).to have_no_download_links
  end
end
