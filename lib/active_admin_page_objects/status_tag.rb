# frozen_string_literal: true

module ActiveAdminPageObjects
  # A `status_tag`. Reached with `row.status_tag(:status)` on an index row or
  # `attributes_table.status_tag(:status)` on a show page.
  class StatusTag < Section
    selector_key :status_tag

    # `has_status_tag?` for the sections whose cells hold status tags.
    module Matchers
      private

      # Waits until the cell +cell_css+ has (+expected+ true) or lacks a
      # status tag with +label+ and +type+. +visible+ is Capybara's option.
      def status_tag_match?(expected, cell_css, label, type, **options)
        visibility = Declarations.visibility(nil, options.delete(:visible))
        eventually(**options) do
          node = first(:css, "#{cell_css} #{sel(:status_tag)}", minimum: 0, wait: false, **visibility)
          (!node.nil? && StatusTag.new(self, node).match?(label, type: type)) == expected
        end
      end
    end

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

    # True when the label equals +label+, ignoring case, and the tag has
    # every class of +type+. Does not wait.
    def match?(label, type: nil)
      same_text?(self.label, label) && (type.nil? || type_match?(type))
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
