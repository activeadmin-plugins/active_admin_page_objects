# frozen_string_literal: true

module ActiveAdminPageObjects
  # A `status_tag`. Reached with `row.status_tag(:status)` on an index row or
  # `attributes_table.status_tag(:status)` on a show page.
  class StatusTag < Section
    selector_key :status_tag

    # The tag text as rendered in the DOM, e.g. "Pending". ActiveAdmin 3's
    # CSS uppercases it on screen, so this reads the text before that.
    # @return [String]
    def label
      root_element.text(:all).strip
    end

    # The CSS classes other than `status_tag`, joined by a space, or nil.
    # @return [String, nil]
    def type
      classes = types
      classes.empty? ? nil : classes.join(" ")
    end

    # True when the tag has every class of +type+ ("pending", or "ok warning").
    def has_type?(type, **options)
      eventually(**options) { type_match?(type) }
    end

    # Waits until the tag lacks the class +type+.
    def has_no_type?(type, **options)
      eventually(**options) { !type_match?(type) }
    end

    # True when the label equals +text+, ignoring case.
    def has_label?(text, **options)
      eventually(**options) { same_text?(label, text) }
    end

    # Waits until the label differs from +text+.
    def has_no_label?(text, **options)
      eventually(**options) { !same_text?(label, text) }
    end

    private

    def types
      root_element[:class].to_s.split - ["status_tag"]
    end

    def type_match?(type)
      expected = type.to_s.split
      expected.any? && (expected - types).empty?
    end
  end
end
