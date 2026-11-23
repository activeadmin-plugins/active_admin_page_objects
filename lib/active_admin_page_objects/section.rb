# frozen_string_literal: true

module ActiveAdminPageObjects
  # Base class for the gem's sections. Subclass it, or any section, to extend.
  class Section < SitePrism::Section
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

    def slug(key)
      ActiveAdminPageObjects.slug(key)
    end

    def same_text?(actual, expected)
      ActiveAdminPageObjects.same_text?(actual, expected)
    end

    def text_match?(actual, expected)
      ActiveAdminPageObjects.text_match?(actual, expected)
    end

    # JavaScript drivers return the resolved `href` property; the attribute is what the page wrote.
    def href_attribute(link)
      link.session.evaluate_script("arguments[0].getAttribute('href')", link).to_s
    rescue Capybara::NotSupportedByDriverError
      link[:href].to_s
    end

    def squish(text)
      ActiveAdminPageObjects.squish(text)
    end

    # Retries the block until it is truthy or Capybara's wait time runs out.
    def eventually(wait: Capybara.default_max_wait_time)
      root_element.synchronize(wait) do
        yield || raise(Capybara::ExpectationNotMet)
      end
      true
    rescue Capybara::ExpectationNotMet
      false
    end
  end
end
