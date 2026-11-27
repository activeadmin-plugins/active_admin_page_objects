# frozen_string_literal: true

module ActiveAdminPageObjects
  # The flash messages under the title bar. ActiveAdmin 3 renders the
  # container on every page, so `has_no_flash?` also works without flashes.
  class Flashes < Section
    selector_key :flashes

    TYPES = %i[notice alert error warning].freeze

    # True when a flash of +type+ contains +text+.
    # @raise [ArgumentError] when +type+ is not one of TYPES
    def has_flash?(type, text = nil, **options)
      has_css?(flash_selector(type), **given(text: text), **options)
    end

    # Waits until no flash of +type+ contains +text+.
    def has_no_flash?(type, text = nil, **options)
      has_no_css?(flash_selector(type), **given(text: text), **options)
    end

    # The flash texts, all of them or those of +type+.
    # @return [Array<String>]
    def messages(type = nil)
      selector = type ? flash_selector(type) : sel(:flash)
      all(selector).map { |el| el.text.strip }
    end

    private

    def flash_selector(type)
      unless type.respond_to?(:to_sym) && TYPES.include?(type.to_sym)
        raise ArgumentError, "flash type must be one of #{TYPES.inspect}, got #{type.inspect}"
      end

      sel(:"flash_#{type}")
    end
  end
end
