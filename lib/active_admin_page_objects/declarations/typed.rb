# frozen_string_literal: true

module ActiveAdminPageObjects
  module Declarations
    # Typed elements: the section class of a filter or field wrapper. The
    # host has `detectable_classes`: formtastic wrapper class => section class.
    module Typed
      private

      # The class for +wrapper+ among #detectable_classes: the first entry whose
      # formtastic class the wrapper carries, or +default+.
      def detected_class(wrapper, default)
        classes = detectable_classes
        classes.fetch((classes.keys & class_names(wrapper)).first, default)
      end

      # The section for +wrapper+: the declared class, or the detected one when
      # nothing is declared.
      # @raise [DeclaredClassMismatch] when the declared class is not the detected one or a subclass of it
      def build_declared(name, declaration, wrapper, default)
        detected = detected_class(wrapper, default)
        return detected.new(self, wrapper) unless declaration

        declared = declaration[:type]
        return declared.new(self, wrapper) if declared <= detected

        raise DeclaredClassMismatch, "#{name.inspect} is declared as #{declared}, but the page has #{detected}"
      end
    end
  end
end
