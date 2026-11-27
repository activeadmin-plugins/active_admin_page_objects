# frozen_string_literal: true

module ActiveAdminPageObjects
  # The `tabs` component. jQuery UI switches the tabs, so #current and #switch
  # need a JavaScript driver; without one every tab body is shown. A tab is
  # named by its whole label, ignoring case, or by a Regexp for a label with a
  # changing part: `switch(/\AOrders \(\d+\)\z/)`.
  class Tabs < Section
    selector_key :tabs

    # The tab labels in document order.
    # @return [Array<String>]
    def labels
      links.map { |link| link.text.strip }
    end

    # The label of the open tab, or nil before jQuery UI has set the tabs up.
    # @return [String, nil]
    def current
      current_link&.text&.strip
    end

    # Opens the tab labelled +label+: a String (case-insensitive) or a Regexp.
    def switch(label)
      link = find_link(label) || raise(Capybara::ElementNotFound, "no tab #{label.inspect} in #{labels.inspect}")
      link.click
    end

    # The body of the open tab, or of the first tab when none is marked open.
    # @return [Capybara::Node::Element]
    def body
      fragment = current_link && current_link[:href].to_s[/#(.+)\z/, 1]
      fragment ? find(:id, fragment) : find(:active_admin, :tab_panel, match: :first)
    end

    # True when there is a tab labelled +label+.
    def has_tab?(label, **options)
      eventually(**options) { find_link(label) }
    end

    # Waits until there is no tab labelled +label+.
    def has_no_tab?(label, **options)
      eventually(**options) { find_link(label).nil? }
    end

    private

    def links
      all(:active_admin, :tab_link)
    end

    def current_link
      first(:active_admin, :tab_current_link, minimum: 0, wait: false)
    end

    def find_link(label)
      links.find { |link| text_match?(link.text, label) }
    end
  end
end
