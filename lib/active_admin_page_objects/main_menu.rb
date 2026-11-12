# frozen_string_literal: true

module ActiveAdminPageObjects
  # The main navigation. Items are found by their label path, e.g.
  # `go("Catalog", "Orders")`, and work under any Capybara driver: the menu is
  # read from the DOM, hidden submenus included, and #go visits the link's URL.
  class MainMenu < Section
    selector_key :main_menu

    ITEM_XPATH = "./ul/li"
    LABEL_XPATH = "./a | ./button | ./div/a"
    LINK_XPATH = "./a | ./div/a"

    # Visits the menu item at the label path +labels+.
    def go(*labels)
      item = find_item(labels) || raise(Capybara::ElementNotFound, "no menu item #{labels.inspect}")
      link = item.first(:xpath, LINK_XPATH, visible: :all, minimum: 0)
      raise ArgumentError, "menu item #{labels.inspect} has no link" if link.nil? || link[:href].to_s.empty? || link[:href] == "#"

      visit(link[:href])
    end

    # True when the menu has an item at the label path +labels+.
    def has_item?(*labels)
      !find_item(labels).nil?
    end

    # True when the menu has no item at the label path +labels+.
    def has_no_item?(*labels)
      find_item(labels).nil?
    end

    # The label path of the current item, e.g. `["Catalog", "Orders"]`.
    # @return [Array<String>]
    def current_labels
      path = current_path_in(root_element)
      path ? path.map { |li| label_of(li) } : []
    end

    private

    def find_item(labels)
      raise ArgumentError, "give at least one label" if labels.empty?

      labels.reduce(root_element) do |scope, label|
        children(scope).find { |li| same_text?(label_of(li), label) } || (return nil)
      end
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
