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
    include RowsByCell

    selector_key :table

    class << self
      # Declares column +key+ with the +label+ of its header: "" for the
      # selection and actions columns. +visible+ is the Capybara option the
      # header and the cells are found with.
      def column(key, label, visible: nil)
        declare(key, label, visible: visible)
      end
    end

    # ActiveAdmin 4 writes no `data-column` on the selection and actions
    # columns: their headers have no title. These are their keys.
    SELECTION_COLUMN = "selectable"
    ACTIONS_COLUMN = "actions"
    private_constant :SELECTION_COLUMN, :ACTIONS_COLUMN

    # One `<tr>` of the table body.
    class Row < Section
      include Declarations::Lookup

      # The record id from the row's `id="<resource>_<id>"`.
      # @return [String]
      def record_id
        root_element[:id].to_s.split("_").last
      end

      # The `<td>` of column +key+ (`:external_id` or `"External ID"`). A
      # hidden cell is found with `visible: :all`.
      # @return [Capybara::Node::Element]
      def cell(key, visible: nil)
        find(:css, cell_selector(key), **visibility_of(key, visible))
      end

      # True when column +key+ has a cell matching the Capybara options. A
      # String `text:` or `exact_text:` ignores case.
      def has_cell?(key, **options)
        has_css?(cell_selector(key), **visibility_of(key), **case_insensitive_text(options))
      end

      # Waits until column +key+ has no cell matching the Capybara options.
      def has_no_cell?(key, **options)
        has_no_css?(cell_selector(key), **visibility_of(key), **case_insensitive_text(options))
      end

      # Ticks the row's batch-action checkbox.
      def select
        find(:active_admin, :table_row_checkbox).check
      end

      private

      # The columns are declared on the table the row belongs to.
      def declaring_class
        parent.class
      end

      def cell_selector(key)
        declaration_for(key)
        sel(:table_cell, slug(key))
      end
    end

    sections :rows, Row, :active_admin, :table_row

    # The row of the record with +record_id+.
    # @raise [ArgumentError] when +record_id+ is not an Integer or a non-empty String
    # @return [Row]
    def row(record_id)
      Row.new(self, find(:css, row_selector(record_id)))
    end

    # True when the body has the row of the record with +record_id+.
    # @raise [ArgumentError] when +record_id+ is not an Integer or a non-empty String
    def has_row?(record_id, **options)
      has_css?(row_selector(record_id), **case_insensitive_text(options))
    end

    # Waits until the body has no row of the record with +record_id+.
    # @raise [ArgumentError] when +record_id+ is not an Integer or a non-empty String
    def has_no_row?(record_id, **options)
      has_no_css?(row_selector(record_id), **case_insensitive_text(options))
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
      header_names_match?(true, names, **options)
    end

    # Waits until the headers differ from +names+.
    # @raise [ArgumentError] when no names are given
    def has_no_header_names?(*names, **options)
      header_names_match?(false, names, **options)
    end

    # `has_declared_columns?`, `has_exact_columns?` and their `has_no_` forms.
    # The exact ones count the selection and actions columns too; none checks
    # the column order.
    Declarations.define_predicates(self, :columns)

    # True when the body has +count+ rows, or any row when +count+ is nil.
    def has_rows?(count: nil, **options)
      has_css?(sel(:table_row), **given(count: count), **options)
    end

    # Waits until the body has no rows, or not +count+ rows.
    def has_no_rows?(count: nil, **options)
      has_no_css?(sel(:table_row), **given(count: count), **options)
    end

    private

    # A record or nil in the selector would match no row, so `has_no_row?` would pass.
    def row_selector(record_id)
      unless record_id.is_a?(Integer) || (record_id.is_a?(String) && !record_id.empty?)
        raise ArgumentError, "record id must be an Integer or a non-empty String, got #{record_id.inspect}"
      end

      sel(:table_row_by_id, record_id)
    end

    def header_names_match?(expected, names, **options)
      raise ArgumentError, "no header names given" if names.empty?

      eventually(**options) { texts_match?(header_names, names) == expected }
    end

    def declared_label_text(key, _declaration, **visibility)
      label_text(sel(:table_column_header, key), **visibility) || untitled_header_label(key, **visibility)
    end

    def page_element_keys(**visibility)
      keyed_headers(**visibility).map(&:first)
    end

    # Each header with its key: its `data-column`, or the key of the selection
    # or actions column. Any other untitled column has no key and is left out.
    def keyed_headers(**visibility)
      all(:active_admin, :table_header, wait: false, **visibility).filter_map do |header|
        key = header[:"data-column"].to_s
        key = untitled_column_key(header) if key.empty?
        [key, header] if key
      end
    end

    # The selection header holds the toggle-all checkbox. The actions header
    # is empty, so the column is known by the actions in its body cells. The
    # checkbox and the actions tell the columns apart, so they are found
    # hidden too.
    def untitled_column_key(header)
      return SELECTION_COLUMN if header.has_css?(sel(:batch_actions_toggle_all), visible: :all, wait: false)

      ACTIONS_COLUMN if has_css?(sel(:table_actions_cell, column_position(header)), visible: :all, wait: false)
    end

    # The 1-based position of +header+ among every header, the hidden ones included.
    def column_position(header)
      header.all(:xpath, "preceding-sibling::*", visible: :all, wait: false).size + 1
    end

    def untitled_header_label(key, **visibility)
      return unless [SELECTION_COLUMN, ACTIONS_COLUMN].include?(key)

      header = keyed_headers(**visibility).assoc(key)&.last
      header && squish(header.text(:all))
    end
  end
end
