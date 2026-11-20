# frozen_string_literal: true

module ActiveAdminPageObjects
  # The sidebar filter form. `filter(:name)` returns the section for the
  # `filter :name` input, typed by the input's class.
  class Filters < Section
    selector_key :filters

    class << self
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
    # @return [Filter]
    def filter(key)
      wrapper = find(:css, sel(:filter, slug(key)))
      filter_class_for(wrapper).new(self, wrapper)
    end

    # Clicks the "Filter" button.
    def submit
      find(:active_admin, :filters_submit).click
    end

    # Clicks "Clear Filters". ActiveAdmin 3 clears in JavaScript, so this
    # needs a JavaScript driver.
    def clear
      find(:active_admin, :filters_clear).click
    end

    private

    def filter_class_for(wrapper)
      classes = wrapper[:class].to_s.split
      self.class.types.each { |input_class, klass| return klass if classes.include?(input_class) }
      Filter
    end
  end
end

require_relative "filters/filter"
require_relative "filters/string_filter"
require_relative "filters/numeric_filter"
require_relative "filters/select_filter"
require_relative "filters/boolean_filter"
require_relative "filters/date_range_filter"
