# frozen_string_literal: true

module ActiveAdminPageObjects
  # A `status_tag`. Reached with `row.status_tag(:status)` on an index row or
  # `attributes_table.status_tag(:status)` on a show page. A cell with several
  # tags gives them with `status_tags(:status)`.
  class StatusTag < Section
    selector_key :status_tag

    # The status tags of a cell, for the sections whose cells hold them. The
    # section names a cell by a key: it has `cell_selector(key)`, and
    # `visibility_of(key, visible)` from Declarations::Lookup.
    module Matchers
      # The status tag in the cell of +key+.
      # @raise [Capybara::Ambiguous] when the cell has several: see #status_tags
      # @return [StatusTag]
      def status_tag(key, visible: nil)
        visibility = visibility_of(key, visible)
        StatusTag.new(self, find(:css, cell_selector(key), **visibility).find(:active_admin, :status_tag, **visibility))
      end

      # Every status tag in the cell of +key+, in page order.
      # @return [Array<StatusTag>]
      def status_tags(key, visible: nil)
        status_tags_in(cell_selector(key), **visibility_of(key, visible))
      end

      # True when a status tag in the cell of +key+ has +label+, ignoring
      # case, and every class of +type+.
      def has_status_tag?(key, label, type: nil, **options)
        status_tag_match?(true, key, label, type, **options)
      end

      # Waits until no status tag in the cell of +key+ is such a tag.
      def has_no_status_tag?(key, label, type: nil, **options)
        status_tag_match?(false, key, label, type, **options)
      end

      private

      # Waits until a status tag of the cell has +label+ and +type+ (+expected+
      # true), or none has. `visible:` is Capybara's option.
      def status_tag_match?(expected, key, label, type, **options)
        cell_css = cell_selector(key)
        visibility = visibility_of(key, options.delete(:visible))
        eventually(**options) do
          tags = status_tags_in(cell_css, **visibility)
          tags.any? { |tag| tag.match?(label, type: type) } == expected
        end
      end

      # The status tags of the cell +cell_css+, in page order, without waiting.
      def status_tags_in(cell_css, **visibility)
        all(:css, "#{cell_css} #{sel(:status_tag)}", wait: false, **visibility).map { |node| StatusTag.new(self, node) }
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
      class_names(root_element) - ["status_tag"]
    end

    def type_match?(type)
      expected = type.to_s.split
      expected.any? && (expected - types).empty?
    end
  end
end
