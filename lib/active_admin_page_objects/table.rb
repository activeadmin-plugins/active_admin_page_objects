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
      # selection and actions columns.
      def column(key, label)
        declare(key, label)
      end
    end

    SORT_DIRECTIONS = %i[asc desc].freeze

    # One `<tr>` of the table body.
    class Row < Section
      include StatusTag::Matchers

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

      # The status tag in the cell of column +key+.
      # @return [StatusTag]
      def status_tag(key)
        StatusTag.new(self, cell(key).find(:active_admin, :status_tag))
      end

      # True when the status tag of column +key+ has +label+, ignoring case,
      # and every class of +type+.
      def has_status_tag?(key, label, type: nil, **options)
        status_tag_match?(true, cell_selector(key), label, type, **options)
      end

      # Waits until column +key+ has no such status tag.
      def has_no_status_tag?(key, label, type: nil, **options)
        status_tag_match?(false, cell_selector(key), label, type, **options)
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

    # The non-empty header texts, as the driver reports them.
    # @return [Array<String>]
    def header_names
      all(:active_admin, :table_header).map { |th| th.text.strip }.reject(&:empty?)
    end

    # The keys of the titled columns, from each header's `col-<key>` class.
    # The selection and actions columns have no title and are left out.
    # @return [Array<String>]
    def column_keys
      all(:active_admin, :table_header).filter_map { |th| column_key(th) unless th.text.strip.empty? }
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
      th && [column_key(th), direction_of(th)]
    end

    # True when column +key+ has a sort link.
    def has_sortable_column?(key)
      declaration_for(key)
      has_css?(sel(:table_sortable_header, slug(key)))
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
    # not checked. +only+ and +except+ take declared keys.
    def has_declared_columns?(only: nil, except: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, **options)
    end

    # Waits until a declared column in scope has another header label, or is missing.
    def has_no_declared_columns?(only: nil, except: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, **options)
    end

    # Like #has_declared_columns?, and the table has no column that is not
    # declared, the selection and actions columns included.
    def has_exact_columns?(only: nil, except: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, **options)
    end

    # Waits until the columns differ from the declared ones.
    def has_no_exact_columns?(only: nil, except: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, **options)
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
      SORT_DIRECTIONS.find { |direction| header[:class].to_s.split.include?("sorted-#{direction}") }
    end

    def column_key(header)
      header[:class].to_s.split.filter_map { |name| name[/\Acol-(.+)\z/, 1] }.first
    end

    def header_names_match?(expected)
      actual = header_names
      actual.size == expected.size && actual.zip(expected).all? { |a, e| same_text?(a, e) }
    end

    def declared_label_text(key, _declaration)
      label_text(sel(:table_column_header, key))
    end

    def page_element_keys
      all(:active_admin, :table_header, visible: :all, wait: false).filter_map { |header| column_key(header) }
    end
  end
end
