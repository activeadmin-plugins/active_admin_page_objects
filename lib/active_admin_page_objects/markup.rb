# frozen_string_literal: true

module ActiveAdminPageObjects
  # Picks the selector map: `:v3`, `:v4` or `:theme_v4`.
  module Markup
    MARKUPS = %i[v3 v4 theme_v4].freeze
    FIRST_V4 = Gem::Version.new("4.0.0.beta1")
    FIRST_THEME_V4 = Gem::Version.new("4.0.0.a")

    # The markup in use, detected on first call unless set explicitly.
    # @return [Symbol]
    def markup
      @markup ||= detect_markup
    end

    # Sets the markup explicitly; `nil` re-enables detection.
    def markup=(value)
      unless value.nil? || MARKUPS.include?(value)
        raise ArgumentError, "markup must be one of #{MARKUPS.inspect}, got #{value.inspect}"
      end

      @markup = value
    end

    # Detects the markup from the loaded ActiveAdmin and theme versions.
    # @return [Symbol]
    def detect_markup
      unless defined?(::ActiveAdmin::VERSION)
        raise UnsupportedMarkup, "ActiveAdmin is not loaded. Load it first or set ActiveAdminPageObjects.markup"
      end
      return :v3 if Gem::Version.new(::ActiveAdmin::VERSION) < FIRST_V4

      theme_v4? ? :theme_v4 : :v4
    end

    private

    def theme_v4?
      defined?(::ActiveAdminTheme::VERSION) && Gem::Version.new(::ActiveAdminTheme::VERSION) >= FIRST_THEME_V4
    end
  end
end
