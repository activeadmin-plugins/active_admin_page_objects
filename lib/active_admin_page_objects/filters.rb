# frozen_string_literal: true

module ActiveAdminPageObjects
  # The sidebar filter form. `filter(:name)` returns the section for the
  # `filter :name` input, typed by the input's class. Declare the filters,
  # their labels and optionally their section class on the section:
  #
  #   section :filters, ActiveAdminPageObjects::Filters do
  #     filter :name, "Name"
  #     filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
  #   end
  class Filters < Section
    include Declarations

    selector_key :filters

    class << self
      # Declares filter +key+ with its +label+. With +type+, `filter(key)`
      # raises unless the page has a filter of that class.
      def filter(key, label, type = nil)
        declare(key, label, type)
      end

      # Filter section class per formtastic input class, shared with subclasses.
      # @return [Hash{String => Class}]
      def types
        @types ||= superclass.respond_to?(:types) ? superclass.types : {}
      end

      # Registers +klass+ for wrappers carrying the +input_class+ CSS class.
      def register_type(input_class, klass)
        types[input_class.to_s] = klass
      end
    end

    # The section for `filter key`, e.g. a StringFilter for a string column.
    # @raise [Capybara::ExpectationNotMet] when the filter is declared with another class
    # @return [Filter]
    def filter(key)
      declaration = declaration_for(key)
      wrapper = find(:css, sel(:filter, slug(key)))
      klass = filter_class_for(wrapper)
      check_declared_type(key, declaration, klass)
      klass.new(self, wrapper)
    end

    # True when every declared filter has exactly its declared label.
    def has_declared_filters?(**options)
      declared_labels?(**options)
    end

    # Waits until a declared filter has another label, or is missing.
    def has_no_declared_filters?(**options)
      no_declared_labels?(**options)
    end

    # Clicks the "Filter" button.
    def submit
      find(:active_admin, :filters_submit).click
    end

    # Clicks "Clear Filters".
    def clear
      find(:active_admin, :filters_clear).click
    end

    private

    def filter_class_for(wrapper)
      classes = wrapper[:class].to_s.split
      self.class.types.each { |input_class, klass| return klass if classes.include?(input_class) }
      Filter
    end

    def declared_label_text(key)
      input_label_text(sel(:filter, key))
    end
  end
end

require_relative "filters/filter"
require_relative "filters/string_filter"
require_relative "filters/numeric_filter"
require_relative "filters/select_filter"
require_relative "filters/boolean_filter"
require_relative "filters/date_range_filter"
