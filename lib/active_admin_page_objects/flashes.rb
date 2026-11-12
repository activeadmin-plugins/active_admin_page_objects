# frozen_string_literal: true

module ActiveAdminPageObjects
  # The flash messages under the page header. ActiveAdmin 4 renders the
  # `notice`, `alert` and `error` types only.
  class Flashes < Section
    selector_key :flashes

    TYPES = %i[notice alert error].freeze

    # True when a flash of +type+ contains +text+.
    def has_flash?(type, text = nil, **options)
      has_css?(flash_selector(type), **text_options(text), **options)
    end

    # Waits until no flash of +type+ contains +text+.
    def has_no_flash?(type, text = nil, **options)
      has_no_css?(flash_selector(type), **text_options(text), **options)
    end

    # The flash texts, all of them or those of +type+.
    # @return [Array<String>]
    def messages(type = nil)
      selector = type ? flash_selector(type) : sel(:flash)
      all(selector).map { |el| el.text.strip }
    end

    private

    def flash_selector(type)
      raise ArgumentError, "flash type must be one of #{TYPES.inspect}, got #{type.inspect}" unless TYPES.include?(type.to_sym)

      sel(:"flash_#{type}")
    end

    def text_options(text)
      text ? { text: text } : {}
    end
  end
end
