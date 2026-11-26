# frozen_string_literal: true

module ActiveAdminPageObjects
  # Text helpers shared by the sections.
  module Text
    # Collapses whitespace runs to one space and strips the ends.
    # @return [String]
    def squish(text)
      text.to_s.gsub(/[[:space:]]+/, " ").strip
    end

    # Squishes whitespace and case-folds, so "ID " matches "Id".
    # @return [String]
    def normalize_text(text)
      squish(text).downcase(:fold)
    end

    # True when both texts are equal after #normalize_text.
    def same_text?(actual, expected)
      normalize_text(actual) == normalize_text(expected)
    end

    # True when +actual+ matches +expected+: a Regexp matches the squished
    # text, anything else compares as #same_text?.
    def text_match?(actual, expected)
      expected.is_a?(Regexp) ? expected.match?(squish(actual)) : same_text?(actual, expected)
    end

    # Capybara options with a String `text:` or `exact_text:` turned into a
    # case-insensitive Regexp in `text:`. Chrome reports CSS-transformed text,
    # so a tag uppercased by the theme still matches "verified".
    # @return [Hash]
    def case_insensitive_text(options)
      text = options[:text]
      exact = options[:exact_text]
      if exact.is_a?(String) && text.nil?
        options.except(:exact_text).merge(text: text_pattern(exact, exact: true))
      elsif text.is_a?(String)
        options.except(:exact_text).merge(text: text_pattern(text, exact: exact == true))
      else
        options
      end
    end

    # A Regexp matching +text+ with any whitespace between its words, ignoring case.
    # @return [Regexp]
    def text_pattern(text, exact: false)
      words = text.to_s.split.map { |word| Regexp.escape(word) }.join("\\s+")
      Regexp.new(exact ? "\\A\\s*#{words}\\s*\\z" : words, Regexp::IGNORECASE)
    end

    # A date as the date inputs take it: "2026-01-31" for a Date or a Time,
    # and the text of anything else.
    # @return [String]
    def iso_date(value)
      value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value.to_s
    end

    # The key ActiveAdmin writes into `data-column` and `data-row`:
    # `"EXTERNAL ID"` and `:external_id` both become `"external_id"`.
    # @return [String]
    def slug(key)
      text = key.to_s
      return text.parameterize(separator: "_") if text.respond_to?(:parameterize)

      text.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
    end
  end
end
