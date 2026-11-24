# frozen_string_literal: true

module ActiveAdminPageObjects
  # Base class for the gem's sections. Subclass it, or any section, to extend.
  class Section < SitePrism::Section
    include Text

    private(*Text.instance_methods)

    class << self
      # Sets the default locator to the selector-map entry +key+, resolved
      # when the section is found.
      def selector_key(key)
        set_default_search_arguments :active_admin, key
      end
    end

    private

    def sel(key, *args)
      ActiveAdminPageObjects.selector(key, *args)
    end

    # The options that are set. Capybara reads `count: nil` and `text: nil`
    # as values to match, so an unset option is left out.
    def given(**options)
      options.compact
    end

    def class_names(node)
      node[:class].to_s.split
    end

    # The key in the node's `<prefix><key>` class: "name" for `col col-name` and "col-".
    def class_key(node, prefix)
      class_names(node).filter_map { |name| name.delete_prefix(prefix) if name.start_with?(prefix) && name != prefix }.first
    end

    # True when +actual+ holds the +expected+ texts, in order, ignoring case.
    def texts_match?(actual, expected)
      actual.size == expected.size && actual.zip(expected).all? { |a, e| same_text?(a, e) }
    end

    # JavaScript drivers return the resolved `href` property; the attribute is what the page wrote.
    def href_attribute(link)
      link.session.evaluate_script("arguments[0].getAttribute('href')", link).to_s
    rescue Capybara::NotSupportedByDriverError
      link[:href].to_s
    end

    # Types +text+ into a date input. jQuery UI opens the datepicker when the
    # input gets focus, over the controls below; Escape closes it.
    def type_date(input, text)
      input.set(text)
      input.send_keys(:escape) if class_names(input).include?("hasDatepicker")
    end

    # Retries the block until it is truthy or the wait time runs out.
    # Capybara's synchronize takes `false` as a number, so it becomes 0 here.
    def eventually(wait: Capybara.default_max_wait_time)
      root_element.synchronize(wait == false ? 0 : wait) do
        yield || raise(Capybara::ExpectationNotMet)
      end
      true
    rescue Capybara::ExpectationNotMet
      false
    end
  end
end
