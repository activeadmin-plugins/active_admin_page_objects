# frozen_string_literal: true

module ActiveAdminPageObjects
  module Declarations
    # Finds the declaration of a name. Declarations includes it; a section
    # whose names are declared on another class, as a table row's are,
    # includes it alone and overrides #declaring_class.
    module Lookup
      private

      def declaring_class
        self.class
      end

      def declarations
        declaring_class.respond_to?(:declarations) ? declaring_class.declarations : {}
      end

      # @raise [ArgumentError] when names are declared and +key+ is not one of them
      def declaration_for(key)
        Declarations.lookup(declarations, key)
      end

      # The `visible:` option for the declared or undeclared element +key+.
      def visibility_of(key, visible = nil)
        Declarations.visibility(declaration_for(key), visible)
      end
    end
  end
end
