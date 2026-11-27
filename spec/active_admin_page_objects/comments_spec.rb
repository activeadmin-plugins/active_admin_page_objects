# frozen_string_literal: true

RSpec.describe ActiveAdminPageObjects::Comments do
  let(:page_class) do
    Class.new(ActiveAdminPageObjects::Page) do
      set_url "/admin/documents/{id}"

      section :comments, ActiveAdminPageObjects::Comments
    end
  end
  let(:show) { page_class.new }
  let(:document) { create_document }

  before { ActiveAdmin::Comment.delete_all }

  def create_comment(body)
    author = AdminUser.find_or_create_by!(name: "Demo Admin")
    ActiveAdmin::Comment.create!(namespace: "admin", resource: document, author: author, body: body)
  end

  it "is empty without comments" do
    show.load(id: document.id)

    expect(show.comments.count).to eq(0)
    expect(show.comments.bodies).to eq([])
    expect(show.comments.authors).to eq([])
    expect(show.comments).to have_no_comment("First comment", wait: 0)
  end

  it "adds a comment" do
    show.load(id: document.id)
    show.comments.add("First comment")

    expect(show.comments).to have_comment("First comment")
    expect(show.comments.count).to eq(1)
    expect(show.comments.bodies).to eq(["First comment"])
    expect(show.comments.authors).to eq(["Demo Admin"])
    expect(ActiveAdmin::Comment.pluck(:body)).to eq(["First comment"])
  end

  it "reads existing comments" do
    create_comment("First comment")
    create_comment("Second comment")
    show.load(id: document.id)

    expect(show.comments.count).to eq(2)
    expect(show.comments.bodies).to eq(["First comment", "Second comment"])
    expect(show.comments.authors).to eq(["Demo Admin", "Demo Admin"])
    expect(show.comments).to have_comment("Second")
    expect(show.comments).to have_no_comment("Third", wait: 0)
  end

  it "deletes a comment by its body" do
    create_comment("First comment")
    create_comment("Second comment")
    show.load(id: document.id)
    show.comments.delete("First comment")

    expect(show.comments).to have_no_comment("First comment")
    expect(show.comments.bodies).to eq(["Second comment"])
    expect(show.comments.count).to eq(1)
    expect(ActiveAdmin::Comment.pluck(:body)).to eq(["Second comment"])
  end

  it "raises when no comment has the text to delete" do
    create_comment("First comment")
    show.load(id: document.id)

    expect { show.comments.delete("Missing") }.to raise_error(Capybara::ElementNotFound, /Missing/)
  end

  context "with rack_test", driver: :rack_test do
    it "reads existing comments" do
      create_comment("First comment")
      show.load(id: document.id)

      expect(show.comments.count).to eq(1)
      expect(show.comments.bodies).to eq(["First comment"])
      expect(show.comments.authors).to eq(["Demo Admin"])
    end
  end
end
