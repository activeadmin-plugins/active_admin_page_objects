# frozen_string_literal: true

module ActiveAdminPageObjects
  # An index table. Declare the columns and their header labels on the section:
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

    SORT_DIRECTIONS = %i[asc desc].freeze

    # One `<tr>` of the table body. `status_tag(:status)`,
    # `status_tags(:status)` and `has_status_tag?` read the cell of a column:
    # see StatusTag::Matchers.
    class Row < Section
      include Declarations::Lookup
      include StatusTag::Matchers

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
      has_css?(row_selector(record_id), **options)
    end

    # Waits until the body has no row of the record with +record_id+.
    # @raise [ArgumentError] when +record_id+ is not an Integer or a non-empty String
    def has_no_row?(record_id, **options)
      has_no_css?(row_selector(record_id), **options)
    end

    # The non-empty header texts, as the driver reports them.
    # @return [Array<String>]
    def header_names
      all(:active_admin, :table_header).map { |th| th.text.strip }.reject(&:empty?)
    end

    # The keys of the titled columns, from each header's `col-<key>` class.
    # The selection and actions columns have no title and are left out.
    # @return [Array<String>]
    def column_keys
      all(:active_admin, :table_header).filter_map { |th| class_key(th, "col-") unless th.text.strip.empty? }
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

    # Clicks the header link of column +key+. With +direction+ (`:asc` or
    # `:desc`) it clicks until the column is sorted that way: the first click
    # on an unsorted column sorts descending.
    # @raise [Capybara::ElementNotFound] when the column is not sortable
    def sort_by(key, direction = nil)
      declaration_for(key)
      return click_sort_link(key) if direction.nil?

      direction = checked_direction(direction)
      2.times do
        current = sort_direction(key)
        break if current == direction

        click_sort_link(key)
        # The click reloads the page; wait for the header to show the new order.
        eventually { sort_direction(key) != current } ||
          raise(Capybara::ExpectationNotMet, "column #{key.inspect} kept its sort order after a click")
      end
    end

    # The sorted column and its direction, e.g. `["name", :desc]`, or nil
    # when no column is sorted.
    # @return [Array(String, Symbol), nil]
    def sorted_by
      th = first(:active_admin, :table_sorted_header, minimum: 0, wait: false)
      th && [class_key(th, "col-"), direction_of(th)]
    end

    # True when column +key+ has a sort link.
    def has_sortable_column?(key)
      has_css?(sel(:table_sortable_header, slug(key)), **visibility_of(key))
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

    def sortable_header(key)
      find(:css, sel(:table_sortable_header, slug(key)))
    end

    def click_sort_link(key)
      sortable_header(key).find(:active_admin, :table_sort_link).click
    end

    def sort_direction(key)
      direction_of(sortable_header(key))
    end

    def checked_direction(direction)
      return direction.to_sym if SORT_DIRECTIONS.include?(direction.to_sym)

      raise ArgumentError, "direction must be one of #{SORT_DIRECTIONS.inspect}, got #{direction.inspect}"
    end

    def direction_of(header)
      SORT_DIRECTIONS.find { |direction| class_names(header).include?("sorted-#{direction}") }
    end

    def declared_label_text(key, _declaration, **visibility)
      label_text(sel(:table_column_header, key), **visibility)
    end

    def page_element_keys(**visibility)
      all(:active_admin, :table_header, wait: false, **visibility).filter_map { |header| class_key(header, "col-") }
    end
  end
end
