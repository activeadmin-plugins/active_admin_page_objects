# frozen_string_literal: true

module ActiveAdminPageObjects
  class Table < Section
    # Finds rows by a cell's text, for tables whose rows have no record id,
    # such as a `table_for` of plain values.
    module RowsByCell
      # The first row whose cell in column +key+ matches +text+: a String
      # matches the whole cell text, a Regexp part of it.
      # @return [Row]
      def row_with(key, text, **options)
        eventually_row(key, text, **options) || raise(Capybara::ElementNotFound, "no row with #{key.inspect} #{text.inspect}")
      end

      # True when a row's cell in column +key+ matches +text+.
      def has_row_with?(key, text, **options)
        eventually(**options) { find_row_with(key, text) }
      end

      # Waits until no row's cell in column +key+ matches +text+.
      def has_no_row_with?(key, text, **options)
        eventually(**options) { find_row_with(key, text).nil? }
      end

      private

      def eventually_row(key, text, **options)
        row = nil
        eventually(**options) { row = find_row_with(key, text) }
        row
      end

      def find_row_with(key, text)
        declaration_for(key)
        cell_css = sel(:table_cell, slug(key))
        rows.find do |row|
          cell = row.first(:css, cell_css, minimum: 0, wait: false, **visibility_of(key))
          cell && text_match?(cell.text, text)
        end
      end
    end
  end
end
