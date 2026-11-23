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

      # True when column +key+ has a cell matching the Capybara options.
      def has_cell?(key, **options)
        has_css?(cell_selector(key), **visibility_of(key), **options)
      end

      # Waits until column +key+ has no cell matching the Capybara options.
      def has_no_cell?(key, **options)
        has_no_css?(cell_selector(key), **visibility_of(key), **options)
      end

      # Ticks the row's batch-action checkbox.
      def select
        find(:active_admin, :table_row_checkbox).check
      end

      private

      # The columns are declared on the table the row belongs to.
      def declaration_for(key)
        Declarations.lookup(parent.class.declarations, key) if parent.class.respond_to?(:declarations)
      end

      def cell_selector(key)
        declaration_for(key)
        sel(:table_cell, slug(key))
      end

      def visibility_of(key, visible = nil)
        Declarations.visibility(declaration_for(key), visible)
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

    # True when every declared column in scope has exactly its declared
    # header label. Columns that are not declared, and the column order, are
    # not checked. +only+ and +except+ take declared keys. +visible+ is
    # Capybara's option, for every column.
    def has_declared_columns?(only: nil, except: nil, visible: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, visible: visible, **options)
    end

    # Waits until a declared column in scope has another header label, or is missing.
    def has_no_declared_columns?(only: nil, except: nil, visible: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, visible: visible, **options)
    end

    # Like #has_declared_columns?, and the table has no column that is not
    # declared, the selection and actions columns included.
    def has_exact_columns?(only: nil, except: nil, visible: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, visible: visible, **options)
    end

    # Waits until the columns differ from the declared ones.
    def has_no_exact_columns?(only: nil, except: nil, visible: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, visible: visible, **options)
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
