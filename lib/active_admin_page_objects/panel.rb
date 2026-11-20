# frozen_string_literal: true

module ActiveAdminPageObjects
  # A panel. Find one by title with `page.panel("Notes")`, or declare it:
  #
  #   section :notes, ActiveAdminPageObjects::Panel, :active_admin_panel, "Notes"
  #
  # Sidebar sections and the comments panel are left out: see Sidebar and Comments.
  class Panel < Section
    selector_key :panel

    # The panel title text.
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

    private

    # JavaScript drivers return the resolved `href` property; the attribute is what the page wrote.
    def href_attribute(link)
      link.session.evaluate_script("arguments[0].getAttribute('href')", link).to_s
    rescue Capybara::NotSupportedByDriverError
      link[:href].to_s
    end
  end
end
