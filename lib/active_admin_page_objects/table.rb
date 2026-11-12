# frozen_string_literal: true

module ActiveAdminPageObjects
  # An index table (`table_for`). Set the expected headers on the section:
  #
  #   section :table, ActiveAdminPageObjects::Table do
  #     self.default_header_names = ["Id", "Name"]
  #   end
  class Table < Section
    selector_key :table

    class << self
      # Header texts `has_header_names?` compares against when given none.
      attr_accessor :default_header_names
    end

    # One `<tr>` of the table body.
    class Row < Section
      # The record id from the row's `id="<resource>_<id>"`.
      # @return [String]
      def record_id
        root_element[:id].to_s.split("_").last
      end

      # The `<td>` of column +key+ (`:external_id` or `"External ID"`).
      # @return [Capybara::Node::Element]
      def cell(key)
        find(:css, cell_selector(key))
      end

      # True when column +key+ has a cell matching the Capybara options.
      def has_cell?(key, **options)
        has_css?(cell_selector(key), **options)
      end

      # Waits until column +key+ has no cell matching the Capybara options.
      def has_no_cell?(key, **options)
        has_no_css?(cell_selector(key), **options)
      end

      # Ticks the row's batch-action checkbox.
      def select
        find(:active_admin, :table_row_checkbox).check
      end

      private

      def cell_selector(key)
        sel(:table_cell, slug(key))
      end
    end

    sections :rows, Row, :active_admin, :table_row

    # The row of the record with +record_id+.
    # @return [Row]
    def row(record_id)
      Row.new(self, find(:css, sel(:table_row_by_id, record_id)))
    end

    # The non-empty header texts, as the driver reports them (Chrome reports
    # CSS-uppercased text).
    # @return [Array<String>]
    def header_names
      all(:active_admin, :table_header).map { |th| th.text.strip }.reject(&:empty?)
    end

    # The `data-column` keys of the headers.
    # @return [Array<String>]
    def column_keys
      all(:active_admin, :table_header).filter_map { |th| th[:"data-column"] }
    end

    # True when the headers equal +names+ (or default_header_names), in order,
    # ignoring case.
    def has_header_names?(*names, **options)
      expected = names.empty? ? self.class.default_header_names : names
      raise ArgumentError, "no header names given and #{self.class}.default_header_names is unset" unless expected

      eventually(**options) { header_names_match?(Array(expected)) }
    end

    # Waits until the headers differ from +names+.
    def has_no_header_names?(*names, **options)
      expected = names.empty? ? self.class.default_header_names : names
      raise ArgumentError, "no header names given and #{self.class}.default_header_names is unset" unless expected

      eventually(**options) { !header_names_match?(Array(expected)) }
    end

    # True when the body has +count+ rows, or any row when +count+ is nil.
    def has_rows?(count: nil, **options)
      has_css?(sel(:table_row), count: count, **options)
    end

    # Waits until the body has no rows, or not +count+ rows.
    def has_no_rows?(count: nil, **options)
      has_no_css?(sel(:table_row), count: count, **options)
    end

    private

    def header_names_match?(expected)
      actual = header_names
      actual.size == expected.size && actual.zip(expected).all? { |a, e| same_text?(a, e) }
    end
  end
end
