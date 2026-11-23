# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Form::FileField do
  let(:form_page) { Pages::DocumentForm.new }
  let(:form) { form_page.form }
  let(:path) { File.expand_path("../fixtures/upload.txt", __dir__) }

  before { form_page.load(action: "new") }

  shared_examples "file field" do
    it "is the class of a file input" do
      expect(form.field(:attachment)).to be_an_instance_of(described_class)
      plain = ActiveAdminPageObjects::Form.new(form_page, form.root_element)
      expect(plain.field(:attachment)).to be_an_instance_of(described_class)
      expect(form).to have_exact_fields
    end

    it "attaches the file" do
      form.field(:attachment).fill(path)
      form.submit
      expect(form_page.flashes).to have_flash(:notice, "Document was successfully created.")
      expect(Document.last.attachment_name).to eq("upload.txt")
    end

    it "is filled with the other fields of the form" do
      form.fill(name: "Contract", attachment: Pathname(path))
      form.submit
      expect(form_page.flashes).to have_flash(:notice, "Document was successfully created.")
      expect(Document.last).to have_attributes(name: "Contract", attachment_name: "upload.txt")
    end

    it "raises for a path without a file" do
      expect { form.field(:attachment).fill("#{path}.missing") }.to raise_error(Capybara::FileNotFound)
    end
  end

  it_behaves_like "file field"

  context "with rack_test", driver: :rack_test do
    it_behaves_like "file field"
  end
end
