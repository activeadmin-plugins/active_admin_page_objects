# frozen_string_literal: true

module ActiveAdminPageObjects
  # Field and filter classes that themes and plugins register for the
  # formtastic wrapper class of their own inputs. A registered class wins over
  # the gem's class when a wrapper carries both wrapper classes.
  module InputClasses
    @fields = {}
    @filters = {}

    class << self
      # Registered classes by wrapper class.
      # @return [Hash{String => Class}]
      attr_reader :fields, :filters

      # +builtin+ with the classes of +registry+ first, so that they win.
      def merge(registry, builtin)
        registry.merge(builtin) { |_wrapper_class, registered, _builtin| registered }
      end

      def register(registry, wrapper_class, klass, base)
        raise ArgumentError, "#{klass.inspect} is not a subclass of #{base}" unless klass.is_a?(Class) && klass <= base

        registry[wrapper_class.to_s] = klass
      end
    end
  end

  class << self
    # `form.field(name)` returns +field_class+ for a field whose wrapper has the
    # formtastic class +wrapper_class+, e.g. `"searchable_select"` for an
    # input declared with `as: :searchable_select`.
    # @raise [ArgumentError] unless +field_class+ is a Form::Field subclass
    def register_field_class(wrapper_class, field_class)
      InputClasses.register(InputClasses.fields, wrapper_class, field_class, Form::Field)
    end

    # `filters.filter(name)` returns +filter_class+ for a filter whose wrapper
    # has the formtastic class +wrapper_class+.
    # @raise [ArgumentError] unless +filter_class+ is a Filter subclass
    def register_filter_class(wrapper_class, filter_class)
      InputClasses.register(InputClasses.filters, wrapper_class, filter_class, Filter)
    end
  end
end
