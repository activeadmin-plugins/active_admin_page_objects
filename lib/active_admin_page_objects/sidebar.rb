# frozen_string_literal: true

module ActiveAdminPageObjects
  # A sidebar section. Find one by title with `page.sidebar("Help")`, or with a
  # Regexp: `page.sidebar(/\AVersions/)`.
  class Sidebar < Panel
    selector_key :sidebar_section

    # The section title text.
    # @return [String]
    def title
      find(:active_admin, :sidebar_title).text.strip
    end

    # The section body node, for content assertions.
    # @return [Capybara::Node::Element]
    def body
      find(:active_admin, :sidebar_body)
    end
  end
end
