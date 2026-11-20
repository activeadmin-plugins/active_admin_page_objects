# frozen_string_literal: true

module ActiveAdminPageObjects
  # An index table (`table_for`). Declare the columns and their header labels
  # on the section:
  #
  #   section :table, ActiveAdminPageObjects::Table do
  #     column :id, "Id"
  #     column :external_id, "External ID"
  #   end
  class Table < Section
    include Declarations

    selector_key :table

    class << self
      # Declares column +key+ with the +label+ of its header. Without a
      # label the key is known but its header is not compared.
      def column(key, label = nil)
        declare(key, label)
      end
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

      # The columns are declared on the table the row belongs to.
      def cell_selector(key)
        Declarations.lookup(parent.class.declarations, key) if parent.class.respond_to?(:declarations)
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

    # True when the headers equal +names+, in order, ignoring case.
    # @raise [ArgumentError] when no names are given
    def has_header_names?(*names, **options)
      raise ArgumentError, "no header names given" if names.empty?

      eventually(**options) { header_names_match?(names) }
    end

    # Waits until the headers differ from +names+.
    # @raise [ArgumentError] when no names are given
    def has_no_header_names?(*names, **options)
      raise ArgumentError, "no header names given" if names.empty?

      eventually(**options) { !header_names_match?(names) }
    end

    # True when every declared column has exactly its declared header label.
    # Columns that are not declared, and the column order, are not checked.
    def has_declared_columns?(**options)
      declared_labels?(**options)
    end

    # Waits until a declared column has another header label, or is missing.
    def has_no_declared_columns?(**options)
      no_declared_labels?(**options)
    end

    # True when the body has +count+ rows, or any row when +count+ is nil.
    def has_rows?(count: nil, **options)
      has_css?(sel(:table_row), **count_option(count), **options)
    end

    # Waits until the body has no rows, or not +count+ rows.
    def has_no_rows?(count: nil, **options)
      has_no_css?(sel(:table_row), **count_option(count), **options)
    end

    private

    # Capybara reads `count: nil` as a count to match, so leave it out when unset.
    def count_option(count)
      count.nil? ? {} : { count: count }
    end

    def header_names_match?(expected)
      actual = header_names
      actual.size == expected.size && actual.zip(expected).all? { |a, e| same_text?(a, e) }
    end

    def declared_label_text(key)
      label_text(sel(:table_column_header, key))
    end
  end
end
