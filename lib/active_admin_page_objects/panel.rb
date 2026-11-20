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
  end
end
