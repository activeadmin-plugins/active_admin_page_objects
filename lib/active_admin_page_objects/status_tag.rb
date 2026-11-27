# frozen_string_literal: true

module ActiveAdminPageObjects
  # A `status_tag`: `<span class="status-tag" data-status="pending">Pending</span>`.
  # Reached with `row.status_tag(:status)` on an index row or
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
        StatusTag.new(self, find(:css, status_tag_selector(key), **visibility))
      end

      # Every status tag in the cell of +key+, in page order.
      # @return [Array<StatusTag>]
      def status_tags(key, visible: nil)
        all(:css, status_tag_selector(key), **visibility_of(key, visible)).map { |node| StatusTag.new(self, node) }
      end

      # True when the cell of +key+ has a status tag with the Capybara options.
      # +label+ is the whole text of the tag, ignoring case: a Regexp matches
      # part of it. +status+ is the tag's `data-status`, e.g. :pending, or
      # true for "yes" and false for "no". `type:` is another name for `status:`.
      # @raise [ArgumentError] when both `status:` and `type:` are given, or one
      #   is not a String, a Symbol, true or false
      def has_status_tag?(key, label = nil, status: nil, type: nil, **options)
        css, query = status_tag_query(key, label, status, type, options)
        has_css?(css, **query)
      end

      # Waits until the cell of +key+ has no such status tag.
      # @raise [ArgumentError] as #has_status_tag? does
      def has_no_status_tag?(key, label = nil, status: nil, type: nil, **options)
        css, query = status_tag_query(key, label, status, type, options)
        has_no_css?(css, **query)
      end

      private

      def status_tag_selector(key, status = nil)
        base = "#{cell_selector(key)} #{sel(:status_tag)}"
        status.nil? ? base : "#{base}#{sel(:status_tag_with_status, Capybara::Selector::CSS.escape(status))}"
      end

      # The CSS and the Capybara options of a status tag lookup. A status
      # that is not one of the accepted kinds would match no tag, so
      # `has_no_status_tag?` would pass.
      def status_tag_query(key, label, status, type, options)
        raise ArgumentError, "give status: or type:, not both" unless status.nil? || type.nil?

        status = StatusTag.status_value(status.nil? ? type : status)
        css = status_tag_selector(key, status)
        [css, { **visibility_of(key), **case_insensitive_text(status_tag_label(label, options)) }]
      end

      def status_tag_label(label, options)
        return options if label.nil?

        label.is_a?(Regexp) ? options.except(:exact_text).merge(text: label) : options.except(:text).merge(exact_text: label)
      end
    end

    class << self
      # The `data-status` value of +status+: nil for none, "yes" for true and
      # "no" for false, as ActiveAdmin writes them.
      # @api private
      # @raise [ArgumentError] when +status+ is not nil, a String, a Symbol, true or false
      # @return [String, nil]
      def status_value(status)
        case status
        when nil then nil
        when true then "yes"
        when false then "no"
        when String, Symbol then status.to_s
        else raise ArgumentError, "status must be a String, a Symbol, true or false, got #{status.inspect}"
        end
      end
    end

    # The tag text as rendered in the DOM, e.g. "Pending", before any CSS
    # `text-transform`.
    # @return [String]
    def label
      squish(root_element.text(:all))
    end

    # The tag's `data-status`, e.g. "pending", or nil when it has none.
    # @return [String, nil]
    def status
      value = root_element[:"data-status"].to_s
      value.empty? ? nil : value
    end

    # True when the tag's `data-status` is +status+ (see Matchers#has_status_tag?).
    # @raise [ArgumentError] when +status+ is not a String, a Symbol, true or false
    def has_status?(status, **options)
      wanted = self.class.status_value(status)
      raise ArgumentError, "status must be given" if wanted.nil?

      eventually(**options) { self.status == wanted }
    end

    # Waits until the tag's `data-status` is not +status+.
    # @raise [ArgumentError] as #has_status? does
    def has_no_status?(status, **options)
      wanted = self.class.status_value(status)
      raise ArgumentError, "status must be given" if wanted.nil?

      eventually(**options) { self.status != wanted }
    end

    # True when the label equals +text+, ignoring case.
    def has_label?(text, **options)
      eventually(**options) { same_text?(label, text) }
    end

    # Waits until the label differs from +text+.
    def has_no_label?(text, **options)
      eventually(**options) { !same_text?(label, text) }
    end
  end

  class Table < Section
    class Row < Section
      include StatusTag::Matchers
    end
  end

  class AttributesTable < Section
    include StatusTag::Matchers
  end
end
