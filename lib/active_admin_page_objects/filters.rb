# frozen_string_literal: true

module ActiveAdminPageObjects
  # The sidebar filter form. `filter(:email)` returns the section for the
  # `filter :email` input, typed by the input's class. Declare the filters
  # with their labels and section classes on the section:
  #
  #   section :filters, ActiveAdminPageObjects::Filters do
  #     filter :email, "Email", ActiveAdminPageObjects::StringFilter
  #     filter :balance, "Balance", ActiveAdminPageObjects::NumericFilter
  #   end
  class Filters < Section
    # The buttons of the filter form. Filters and FiltersFooter include it.
    module Buttons
      # Clicks the "Filter" button.
      def submit
        find(:active_admin, :filters_submit).click
      end

      # Clicks "Clear Filters".
      def clear
        find(:active_admin, :filters_clear).click
      end
    end

    include Declarations
    include Declarations::Typed
    include Buttons

    selector_key :filters

    # The name of the gem's filter class per formtastic wrapper class. The
    # first entry whose class the wrapper carries wins.
    FILTER_CLASSES = {
      "string" => :StringFilter,
      "numeric" => :NumericFilter,
      "select" => :SelectFilter,
      "boolean" => :BooleanFilter,
      "date_range" => :DateRangeFilter
    }.freeze
    private_constant :FILTER_CLASSES

    class << self
      # Declares the filter +name+ with its +label+ and its section class
      # +type+. +name+ is the key given to ActiveAdmin's `filter`. +visible+
      # is the Capybara option the filter is found with.
      def filter(name, label, type, visible: nil)
        declare_typed(:filter, name, label, type: type, visible: visible)
      end
    end

    # The filter +name+: its declared class, or else the gem's class for the
    # input, e.g. a StringFilter for a string column. A hidden filter is found
    # with `visible: :all`.
    # @raise [DeclaredClassMismatch] when the page has a filter of another
    #   class than the declared one
    # @return [Filter]
    def filter(name, visible: nil)
      declaration = declaration_for(name)
      wrapper = find(:css, sel(:filter, slug(name)), **Declarations.visibility(declaration, visible))
      build_declared(name, declaration, wrapper, Filter)
    end

    # `has_declared_filters?`, `has_exact_filters?` and their `has_no_` forms.
    Declarations.define_predicates(self, :filters)

    private

    def detectable_classes
      FILTER_CLASSES.transform_values { |name| ActiveAdminPageObjects.const_get(name) }
    end

    def declared_label_text(name, _declaration, **visibility)
      wrapper_label_text(sel(:filter, name), **visibility)
    end

    def page_element_keys(**visibility)
      wrappers = all(:css, sel(:filter_wrappers), wait: false, **visibility)
      wrappers.filter_map { |wrapper| wrapper[:id].to_s[/\Aq_(.+)_input\z/, 1] }
    end
  end
end

require_relative "filters/filter"
require_relative "filters/string_filter"
require_relative "filters/numeric_filter"
require_relative "filters/select_filter"
require_relative "filters/boolean_filter"
require_relative "filters/date_range_filter"
