# frozen_string_literal: true

module ActiveAdminPageObjects
  # The attributes table of a show page. Rows are keyed by the `row :foo`
  # symbol, or by the label parameterized with `_`.
  class AttributesTable < Section
    selector_key :attributes_table

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
      find(:css, sel(:attributes_table_row, slug(key)))
    end

    # The value text of row +key+.
    # @return [String]
    def value(key)
      find(:css, cell_selector(key)).text.strip
    end

    # The status tag in the value cell of row +key+.
    # @return [StatusTag]
    def status_tag(key)
      StatusTag.new(self, find(:css, cell_selector(key)).find(:active_admin, :status_tag))
    end

    private

    def cell_selector(key)
      "#{sel(:attributes_table_row, slug(key))} > td"
    end
  end
end
