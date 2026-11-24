# frozen_string_literal: true

module ActiveAdminPageObjects
  # The main navigation. Items are found by their label path, e.g.
  # `go("Catalog", "Orders")`, and work under any Capybara driver: the menu is
  # read from the DOM, hidden submenus included, and #go visits the link's URL.
  # #click moves through the visible menu as a user does.
  class MainMenu < Section
    selector_key :main_menu

    # The root is the `ul` itself; a nested item holds its submenu in a `ul`.
    ITEM_XPATH = "./li | ./ul/li"
    LABEL_XPATH = "./a | ./span"
    LINK_XPATH = "./a"

    # Visits the menu item at the label path +labels+.
    def go(*labels)
      item = find_item(labels) || raise(Capybara::ElementNotFound, "no menu item #{labels.inspect}")
      link = item.first(:xpath, LINK_XPATH, visible: :all, minimum: 0)
      href = link ? link[:href].to_s : ""
      # A parent item links to "#", which a browser reports as the page URL plus "#".
      raise ArgumentError, "menu item #{labels.inspect} has no link" if href.empty? || href.end_with?("#")

      visit(href)
    end

    # Navigates to the menu item at the label path +labels+ as a user does:
    # hovers each parent, then clicks the item's link. It sees visible items
    # only, so a submenu that stays hidden raises Capybara::ElementNotFound.
    # A driver without hover support skips the hovering.
    def click(*labels)
      raise ArgumentError, "give at least one label" if labels.empty?

      root_element.synchronize do
        *parents, last = labels
        scope = parents.reduce(root_element) { |current, label| hover(visible_item(current, label, labels)) }
        visible_item(scope, last, labels).find(:xpath, LINK_XPATH, wait: false).click
      end
    end

    # True when the menu has an item at the label path +labels+.
    def has_item?(*labels, **options)
      eventually(**options) { find_item(labels) }
    end

    # Waits until the menu has no item at the label path +labels+.
    def has_no_item?(*labels, **options)
      eventually(**options) { find_item(labels).nil? }
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
      current_path_in(root_element).map { |li| label_of(li) }
    end

    private

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

    def hover(item)
      item.find(:xpath, LABEL_XPATH, wait: false).hover
      item
    rescue Capybara::NotSupportedByDriverError
      item
    end

    def children(scope)
      scope.all(:xpath, ITEM_XPATH, visible: :all, wait: false)
    end

    def label_of(item)
      item.first(:xpath, LABEL_XPATH, visible: :all, minimum: 0)&.text(:all).to_s.strip
    end

    # ActiveAdmin marks the current item and each of its parents.
    def current_path_in(scope)
      current = children(scope).find { |li| li.matches_css?(sel(:main_menu_selected), visible: :all, wait: false) }
      current ? [current, *current_path_in(current)] : []
    end
  end
end
