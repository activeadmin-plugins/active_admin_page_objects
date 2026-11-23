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
    include Declarations

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
    # @raise [Capybara::ExpectationNotMet] when the page has a filter of
    #   another class than the declared one
    # @return [Filter]
    def filter(name, visible: nil)
      declaration = declaration_for(name)
      wrapper = find(:css, sel(:filter, slug(name)), **Declarations.visibility(declaration, visible))
      build_declared(name, declaration, filter_class_for(wrapper), wrapper)
    end

    # True when every declared filter in scope has exactly its declared
    # label. +only+ and +except+ take declared names. +visible+ is Capybara's
    # option, for every filter.
    def has_declared_filters?(only: nil, except: nil, visible: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, visible: visible, **options)
    end

    # Waits until a declared filter in scope has another label, or is missing.
    def has_no_declared_filters?(only: nil, except: nil, visible: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, visible: visible, **options)
    end

    # Like #has_declared_filters?, and the page has no filter that is not declared.
    def has_exact_filters?(only: nil, except: nil, visible: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, visible: visible, **options)
    end

    # Waits until the filters differ from the declared ones.
    def has_no_exact_filters?(only: nil, except: nil, visible: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, visible: visible, **options)
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

    # The gem's class for the wrapper's formtastic class, or Filter.
    def filter_class_for(wrapper)
      input_class = (FILTER_CLASSES.keys & wrapper[:class].to_s.split).first
      input_class ? ActiveAdminPageObjects.const_get(FILTER_CLASSES[input_class]) : Filter
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
