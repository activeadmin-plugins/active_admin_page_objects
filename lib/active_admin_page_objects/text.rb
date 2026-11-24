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
