# frozen_string_literal: true

module ActiveAdminPageObjects
  # Names and labels declared on a section class. AttributesTable, Table,
  # Filters and Form include it and add their own class method:
  #
  #   section :attributes_table, ActiveAdminPageObjects::AttributesTable do
  #     row :external_id, "External ID"
  #   end
  #
  # A section with declarations raises ArgumentError for any other name, and
  # compares the declared elements and their labels with the page.
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
      # @return [Hash{String => Hash}] name => `{ label: }`, with `type:`,
      #   and `kind:` for filters and fields
      def declarations
        inherited = superclass.respond_to?(:declarations) ? superclass.declarations : {}
        inherited.merge(own_declarations).freeze
      end

      private

      def declare(name, label, **options)
        own_declarations[ActiveAdminPageObjects.slug(name)] = { label: label.to_s, **options }.freeze
      end

      # Declares +name+ with its section class.
      def declare_typed(kind, name, label, type:)
        raise ArgumentError, "`#{kind} #{name.inspect}` needs a section class, got #{type.inspect}" unless type.is_a?(Class)

        declare(name, label, type: type, kind: kind)
      end

      def own_declarations
        @own_declarations ||= {}
      end
    end

    # The declared names whose label on the page differs from the declaration,
    # each with the label found, or nil when the page has no such element.
    # Empty when every declared label matches. +only+ and +except+ narrow the
    # declared names that are compared.
    # @raise [ArgumentError] when the section declares nothing, or for a name that is not declared
    # @return [Hash{String => String, nil}]
    def declared_label_mismatches(only: nil, except: nil)
      declarations_in_scope(only, except).each_with_object({}) do |(name, declaration), mismatches|
        actual = declared_label_text(name, declaration)
        mismatches[name] = actual unless actual == declaration[:label]
      end
    end

    # What keeps the page from matching the declarations exactly: the declared
    # names the page lacks, the elements on the page that are not declared, and
    # the labels that differ. With +only+ nothing is unexpected.
    # @raise [ArgumentError] when the section declares nothing, or for a name that is not declared
    # @return [Hash] `{ missing: [name], unexpected: [key], labels: { name => label found } }`
    def exact_mismatches(only: nil, except: nil)
      missing, labels = declared_label_mismatches(only: only, except: except).partition { |_name, actual| actual.nil? }
      { missing: missing.map(&:first), unexpected: only ? [] : undeclared_element_keys, labels: labels.to_h }
    end

    private

    def declaration_for(key)
      Declarations.lookup(self.class.declarations, key)
    end

    # The section for +wrapper+: the declared class, or +detected+ when nothing is declared.
    def build_declared(name, declaration, detected, wrapper)
      return detected.new(self, wrapper) unless declaration

      declared = declaration[:type]
      return declared.new(self, wrapper) if declared <= detected

      raise Capybara::ExpectationNotMet, "#{name.inspect} is declared as #{declared}, but the page has #{detected}"
    end

    def declarations_in_scope(only, except)
      declarations = self.class.declarations
      raise ArgumentError, "the section declares no labels" if declarations.empty?

      only, except = [only, except].map { |names| declared_names(names) }
      declarations.select { |name, _| (only.nil? || only.include?(name)) && !except&.include?(name) }
    end

    def declared_names(names)
      names && Array(names).map do |name|
        declaration_for(name)
        slug(name)
      end
    end

    def undeclared_element_keys
      page_element_keys - self.class.declarations.keys
    end

    # Waits until the page matches the declarations in scope (+expected+ true)
    # or stops matching them. With +exact+ the page has no other element either.
    def declared_match?(expected, exact:, only: nil, except: nil, **options)
      declarations_in_scope(only, except)
      scope = { only: only, except: except }
      eventually(**options) do
        mismatches = exact ? exact_mismatches(**scope).values : [declared_label_mismatches(**scope)]
        mismatches.all?(&:empty?) == expected
      end
    end

    # The DOM text of the first element matching +css+, or nil without one.
    # `text(:all)` is the text before CSS `text-transform`, on every driver.
    def label_text(css)
      element = first(:css, css, minimum: 0, wait: false, visible: :all)
      element && squish(element.text(:all))
    end

    # The label of the formtastic wrapper +wrapper_css+: nil without the
    # wrapper, "" when it has no label. The first `label` is the input's own:
    # radio and check_boxes wrappers carry it in the legend, before the labels
    # of the choices.
    def wrapper_label_text(wrapper_css)
      wrapper = first(:css, wrapper_css, minimum: 0, wait: false, visible: :all)
      return unless wrapper

      label = wrapper.first(:css, "label", minimum: 0, wait: false, visible: :all)
      label ? own_text(label) : ""
    end

    # The text of +element+ without the text of the links, buttons and `abbr`
    # inside it: formtastic's required marker, and controls that plugins
    # append to labels (the date range preset's "Set range").
    def own_text(element)
      text = element.text(:all)
      element.all(:css, "a, button, abbr", minimum: 0, wait: false, visible: :all).each do |child|
        text = text.sub(child.text(:all), "")
      end
      squish(text)
    end
  end
end
