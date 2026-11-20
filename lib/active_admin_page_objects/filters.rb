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
  #
  # Each declaration defines a method of its name: `filters.balance`.
  class Filters < Section
    include Declarations

    selector_key :filters

    class << self
      # Declares the filter +name+ with its +label+ and its section class
      # +type+, and defines the method +name+ that returns it. +attribute+ is
      # the key given to ActiveAdmin's `filter`, when it differs from +name+.
      # @raise [ArgumentError] when the section already has a method +name+
      def filter(name, label, type, attribute: name)
        declare_accessor(:filter, name, label, type: type, attribute: attribute)
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

    # The filter +name+: its declared class, or else the class registered for
    # the input, e.g. a StringFilter for a string column.
    # @raise [Capybara::ExpectationNotMet] when the page has a filter of
    #   another class than the declared one
    # @return [Filter]
    def filter(name)
      declaration = declaration_for(name)
      wrapper = find(:css, sel(:filter, declaration ? declaration[:attribute] : slug(name)))
      build_declared(name, declaration, filter_class_for(wrapper), wrapper)
    end

    # True when every declared filter in scope has exactly its declared
    # label. +only+ and +except+ take declared names.
    def has_declared_filters?(only: nil, except: nil, **options)
      declared_match?(true, exact: false, only: only, except: except, **options)
    end

    # Waits until a declared filter in scope has another label, or is missing.
    def has_no_declared_filters?(only: nil, except: nil, **options)
      declared_match?(false, exact: false, only: only, except: except, **options)
    end

    # Like #has_declared_filters?, and the page has no filter that is not declared.
    def has_exact_filters?(only: nil, except: nil, **options)
      declared_match?(true, exact: true, only: only, except: except, **options)
    end

    # Waits until the filters differ from the declared ones.
    def has_no_exact_filters?(only: nil, except: nil, **options)
      declared_match?(false, exact: true, only: only, except: except, **options)
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

    def declared_label_text(_name, declaration)
      wrapper_label_text(sel(:filter, declaration[:attribute]))
    end

    def page_element_keys
      wrappers = all(:css, sel(:filter_wrappers), visible: :all, wait: false)
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
