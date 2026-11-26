# frozen_string_literal: true

require "uri"

module ActiveAdminPageObjects
  # The main navigation. Items are found by their label path, e.g.
  # `go("Catalog", "Orders")`, and work under any Capybara driver: the menu is
  # read from the DOM, hidden submenus included, and #go visits the link's URL.
  # #click moves through the visible menu as a user does.
  class MainMenu < Section
    selector_key :main_menu

    ITEM_XPATH = "./ul/li"
    LABEL_XPATH = "./a | ./button | ./div/a"
    LINK_XPATH = "./a | ./div/a"
    TOGGLE_XPATH = "./button | ./div/button"
    SUBMENU_XPATH = "./ul"

    # Visits the menu item at the label path +labels+.
    def go(*labels)
      visit(href(*labels))
    end

    # The URL of the menu item at the label path +labels+, as the driver
    # reports it: a browser driver gives the absolute URL. #has_item? with
    # +href:+ compares a path to either form.
    # @raise [ArgumentError] when the item has no link
    # @return [String]
    def href(*labels)
      item = find_item(labels) || raise(Capybara::ElementNotFound, "no menu item #{labels.inspect}")
      link_href(item) || raise(ArgumentError, "menu item #{labels.inspect} has no link")
    end

    # Navigates to the menu item at the label path +labels+ as a user does:
    # opens each collapsed parent with its toggle button, then clicks the item's
    # link. It sees visible items only, so a submenu that stays hidden raises
    # Capybara::ElementNotFound.
    def click(*labels)
      raise ArgumentError, "give at least one label" if labels.empty?

      root_element.synchronize do
        *parents, last = labels
        scope = parents.reduce(root_element) { |current, label| expand(visible_item(current, label, labels)) }
        visible_item(scope, last, labels).find(:xpath, LINK_XPATH, wait: false).click
      end
    end

    # True when the menu has an item at the label path +labels+, linking to
    # +href+ when given: a path ("/admin/orders?scope=open"), a full URL, or a
    # Regexp.
    def has_item?(*labels, href: nil, **options)
      eventually(**options) { item_with_href?(labels, href) }
    end

    # Waits until the menu has no item at the label path +labels+, or none
    # linking to +href+ when given.
    def has_no_item?(*labels, href: nil, **options)
      eventually(**options) { !item_with_href?(labels, href) }
    end

    # The labels of the top-level items, or of the submenu at the label path
    # +parents+, in menu order: `labels("Catalog") # => ["Categories", "Orders"]`.
    # @return [Array<String>]
    def labels(*parents)
      scope = parents.empty? ? root_element : find_item(parents)
      raise Capybara::ElementNotFound, "no menu item #{parents.inspect}" if scope.nil?

      children(scope).map { |li| label_of(li) }
    end

    # The label path of the current item, e.g. `["Catalog", "Orders"]`.
    # @return [Array<String>]
    def current_labels
      path = current_path_in(root_element)
      path ? path.map { |li| label_of(li) } : []
    end

    private

    def item_with_href?(labels, expected)
      item = find_item(labels)
      return false if item.nil?

      expected.nil? || href_matches?(link_href(item), expected)
    end

    def link_href(item)
      href = item.first(:xpath, LINK_XPATH, visible: :all, minimum: 0, wait: false)&.[](:href).to_s
      href unless href.empty? || href == "#"
    end

    # A browser driver reports the absolute URL, so a path is compared to the
    # URL's path and query.
    def href_matches?(actual, expected)
      return false if actual.nil?
      return expected.match?(actual) if expected.is_a?(Regexp)
      return actual == expected unless expected.start_with?("/")

      uri = URI.parse(actual)
      [uri.path, uri.query].compact.join("?") == expected
    rescue URI::InvalidURIError
      false
    end

    def find_item(labels)
      raise ArgumentError, "give at least one label" if labels.empty?

      labels.reduce(root_element) do |scope, label|
        children(scope).find { |li| same_text?(label_of(li), label) } || (return nil)
      end
    end

    def visible_item(scope, label, path)
      scope.all(:xpath, ITEM_XPATH, wait: false).find { |li| same_text?(label_of(li), label) } ||
        raise(Capybara::ElementNotFound, "no visible menu item #{label.inspect} in #{path.inspect}")
    end

    def expand(item)
      item.first(:xpath, TOGGLE_XPATH, minimum: 0, wait: false)&.click unless item.has_xpath?(SUBMENU_XPATH, wait: false)
      item
    end

    def children(scope)
      scope.all(:xpath, ITEM_XPATH, visible: :all, wait: false)
    end

    def label_of(item)
      item.first(:xpath, LABEL_XPATH, visible: :all, minimum: 0)&.text(:all).to_s.strip
    end

    def current_path_in(scope)
      children(scope).each do |li|
        return [li] if li.has_xpath?(LINK_XPATH, visible: :all, wait: false) &&
                       li.first(:xpath, LINK_XPATH, visible: :all).matches_css?(sel(:main_menu_selected), wait: false)

        nested = current_path_in(li)
        return [li, *nested] if nested
      end
      nil
    end
  end
end
