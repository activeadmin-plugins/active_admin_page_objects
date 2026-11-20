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
    include StatusTag::Matchers

    selector_key :attributes_table

    class << self
      # Declares row +key+ with the +label+ of its header cell.
      def row(key, label)
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

    # The status tag in the value cell of row +key+.
    # @return [StatusTag]
    def status_tag(key)
      StatusTag.new(self, find(:css, cell_selector(key)).find(:active_admin, :status_tag))
    end

    # True when the status tag of row +key+ has +label+, ignoring case, and
    # every class of +type+.
    def has_status_tag?(key, label, type: nil, **options)
      status_tag_match?(true, cell_selector(key), label, type, **options)
    end

    # Waits until row +key+ has no such status tag.
    def has_no_status_tag?(key, label, type: nil, **options)
      status_tag_match?(false, cell_selector(key), label, type, **options)
    end

    # True when every declared row in scope has exactly its declared label.
    # +only+ and +except+ take declared keys.
    def has_declared_rows?(only: nil, except: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, **options)
    end

    # Waits until a declared row in scope has another label, or is missing.
    def has_no_declared_rows?(only: nil, except: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, **options)
    end

    # Like #has_declared_rows?, and the table has no row that is not declared.
    def has_exact_rows?(only: nil, except: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, **options)
    end

    # Waits until the rows differ from the declared ones.
    def has_no_exact_rows?(only: nil, except: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, **options)
    end

    private

    def row_selector(key)
      declaration_for(key)
      sel(:attributes_table_row, slug(key))
    end

    def cell_selector(key)
      "#{row_selector(key)} > td"
    end

    def declared_label_text(key, _declaration)
      label_text("#{sel(:attributes_table_row, key)} > th")
    end

    def page_element_keys
      all(:css, sel(:attributes_table_rows), visible: :all, wait: false).filter_map do |row|
        row[:class].to_s.split.filter_map { |name| name[/\Arow-(.+)\z/, 1] }.first
      end
    end
  end
end
