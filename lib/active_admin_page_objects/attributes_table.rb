# frozen_string_literal: true

module ActiveAdminPageObjects
  # The attributes table of a show page. Rows are keyed by the `row :foo`
  # symbol, or by the label parameterized with `_`. Declare the rows and
  # their labels on the section:
  #
  #   section :attributes_table, ActiveAdminPageObjects::AttributesTable do
  #     row :name, "Name"
  #     row :external_id, "External ID"
  #   end
  class AttributesTable < Section
    include Declarations

    selector_key :attributes_table

    class << self
      # Declares row +key+ with the +label+ of its header cell. Without a
      # label the key is known (for `has_no_row?`) but not compared.
      def row(key, label = nil)
        declare(key, label)
      end
    end

    # True when row +key+ has a value cell matching the Capybara options.
    def has_row?(key, **options)
      has_css?(cell_selector(key), **options)
    end

    # Waits until row +key+ has no value cell matching the Capybara options.
    def has_no_row?(key, **options)
      has_no_css?(cell_selector(key), **options)
    end

    # The `<tr>` of row +key+.
    # @return [Capybara::Node::Element]
    def row(key)
      find(:css, row_selector(key))
    end

    # The value text of row +key+.
    # @return [String]
    def value(key)
      find(:css, cell_selector(key)).text.strip
    end

    # True when every declared row has exactly its declared label.
    def has_declared_rows?(**options)
      declared_labels?(**options)
    end

    # Waits until a declared row has another label, or is missing.
    def has_no_declared_rows?(**options)
      no_declared_labels?(**options)
    end

    private

    def row_selector(key)
      declaration_for(key)
      sel(:attributes_table_row, slug(key))
    end

    def cell_selector(key)
      "#{row_selector(key)} > td"
    end

    def declared_label_text(key)
      label_text("#{sel(:attributes_table_row, key)} > th")
    end
  end
end
