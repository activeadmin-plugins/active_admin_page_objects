# frozen_string_literal: true

module ActiveAdminPageObjects
  # A panel. Find one by title with `page.panel("Notes")`, or declare it:
  #
  #   section :notes, ActiveAdminPageObjects::Panel, :active_admin_panel, "Notes"
  #
  # The title is a String, compared whole and ignoring case, or a Regexp for a
  # title with a changing part: `page.panel(/\ARoutes \(\d+\)\z/)`.
  class Panel < Section
    selector_key :panel

    # The panel title text. The panel's own title and body come before those
    # of a panel nested in its body.
    # @return [String]
    def title
      find(:active_admin, :panel_title, match: :first).text.strip
    end

    # The panel body node, for content assertions.
    # @return [Capybara::Node::Element]
    def body
      find(:active_admin, :panel_body, match: :first)
    end

    # The links in the body: the text and the `href` attribute as written.
    # @return [Array<Hash{Symbol => String}>] `{ text:, href: }` per link
    def links
      body.all("a", wait: false).map { |link| { text: link.text.strip, href: href_attribute(link) } }
    end
  end
end
