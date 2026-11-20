# frozen_string_literal: true

module ActiveAdminPageObjects
  # Keys and labels declared on a section class. AttributesTable, Table,
  # Filters and Form include it and add their own class method:
  #
  #   section :attributes_table, ActiveAdminPageObjects::AttributesTable do
  #     row :external_id, "External ID"
  #   end
  #
  # A section with declarations raises ArgumentError for any other key, and
  # compares the declared labels with the page.
  module Declarations
    def self.included(base)
      base.extend(ClassMethods)
    end

    # The declaration of +key+ in +declarations+, or nil when nothing is declared.
    # @raise [ArgumentError] when keys are declared and +key+ is not one of them
    # @return [Hash, nil]
    def self.lookup(declarations, key)
      return if declarations.empty?

      declarations.fetch(ActiveAdminPageObjects.slug(key)) do
        raise ArgumentError, "#{key.inspect} is not declared; declared keys: #{declarations.keys.join(', ')}"
      end
    end

    module ClassMethods
      # The declarations of this class and its superclasses, in declaration
      # order. A subclass adds to its own copy.
      # @return [Hash{String => Hash}] key => `{ label:, type: }`
      def declarations
        inherited = superclass.respond_to?(:declarations) ? superclass.declarations : {}
        inherited.merge(own_declarations).freeze
      end

      private

      def declare(key, label, type = nil)
        own_declarations[ActiveAdminPageObjects.slug(key)] = { label: label.to_s, type: type }.freeze
      end

      def own_declarations
        @own_declarations ||= {}
      end
    end

    # The declared keys whose label on the page differs from the declaration,
    # each with the label found, or nil when the page has no such label.
    # Empty when every declared label matches.
    # @raise [ArgumentError] when the section declares nothing
    # @return [Hash{String => String, nil}]
    def declared_label_mismatches
      declarations = self.class.declarations
      raise ArgumentError, "the section declares no labels" if declarations.empty?

      declarations.each_with_object({}) do |(key, declaration), mismatches|
        actual = declared_label_text(key)
        mismatches[key] = actual unless actual == declaration[:label]
      end
    end

    private

    def declaration_for(key)
      Declarations.lookup(self.class.declarations, key)
    end

    def check_declared_type(key, declaration, actual)
      expected = declaration && declaration[:type]
      return if expected.nil? || actual <= expected

      raise Capybara::ExpectationNotMet, "#{key.inspect} is declared as #{expected}, but the page has #{actual}"
    end

    def declared_labels?(**options)
      eventually(**options) { declared_label_mismatches.empty? }
    end

    def no_declared_labels?(**options)
      eventually(**options) { declared_label_mismatches.any? }
    end

    # The DOM text of the first element matching +css+, or nil without one.
    # `text(:all)` is the text before CSS `text-transform`, on every driver.
    def label_text(css)
      element = first(:css, css, minimum: 0, wait: false, visible: :all)
      element && ActiveAdminPageObjects.squish(element.text(:all))
    end

    # The label of the formtastic wrapper +wrapper_css+, without the required
    # marker. The first `label` is the input's own: radio and check_boxes
    # wrappers carry it in the legend, before the labels of the choices.
    def input_label_text(wrapper_css)
      label = first(:css, "#{wrapper_css} label", minimum: 0, wait: false, visible: :all)
      return unless label

      marker = label.first(:css, "abbr", minimum: 0, wait: false, visible: :all)
      text = ActiveAdminPageObjects.squish(label.text(:all))
      marker ? text.delete_suffix(ActiveAdminPageObjects.squish(marker.text(:all))).strip : text
    end
  end
end
