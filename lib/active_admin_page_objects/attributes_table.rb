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
  #
  # `status_tag(:status)`, `status_tags(:status)` and `has_status_tag?` read
  # the value cell of a row: see StatusTag::Matchers.
  class AttributesTable < Section
    include Declarations
    include StatusTag::Matchers

    selector_key :attributes_table

    class << self
      # Declares row +key+ with the +label+ of its header cell. +visible+ is
      # the Capybara option the row is found with.
      def row(key, label, visible: nil)
        declare(key, label, visible: visible)
      end
    end

    # True when row +key+ has a value cell matching the Capybara options.
    def has_row?(key, **options)
      has_css?(cell_selector(key), **visibility_of(key), **options)
    end

    # Waits until row +key+ has no value cell matching the Capybara options.
    def has_no_row?(key, **options)
      has_no_css?(cell_selector(key), **visibility_of(key), **options)
    end

    # The `<tr>` of row +key+. A hidden row is found with `visible: :all`.
    # @return [Capybara::Node::Element]
    def row(key, visible: nil)
      find(:css, row_selector(key), **visibility_of(key, visible))
    end

    # The value text of row +key+: the DOM text when the lookup takes hidden rows.
    # @return [String]
    def value(key, visible: nil)
      visibility = visibility_of(key, visible)
      text_of(find(:css, cell_selector(key), **visibility), visibility).strip
    end

    # `has_declared_rows?`, `has_exact_rows?` and their `has_no_` forms.
    Declarations.define_predicates(self, :rows)

    private

    def row_selector(key)
      declaration_for(key)
      sel(:attributes_table_row, slug(key))
    end

    def cell_selector(key)
      "#{row_selector(key)} > td"
    end

    def declared_label_text(key, _declaration, **visibility)
      label_text("#{sel(:attributes_table_row, key)} > th", **visibility)
    end

    def page_element_keys(**visibility)
      all(:css, sel(:attributes_table_rows), wait: false, **visibility).filter_map { |row| class_key(row, "row-") }
    end
  end
end
