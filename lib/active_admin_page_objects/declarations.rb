# frozen_string_literal: true

require_relative "declarations/lookup"
require_relative "declarations/typed"

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
  #
  # Lookups and matchers see what Capybara finds by default: the visible
  # elements. `visible:` on a declaration sets another default for that
  # element, and `visible:` on a call overrides both.
  module Declarations
    def self.included(base)
      base.extend(ClassMethods)
      base.include(Lookup)
    end

    # The Capybara `visible:` option as a hash: empty for nil, so Capybara's
    # default applies.
    # @api private
    # @return [Hash]
    def self.visible_option(visible)
      { visible: visible }.compact
    end

    # The Capybara `visible:` option of an element: +visible+ when given, or
    # else the one of its +declaration+.
    # @api private
    # @return [Hash]
    def self.visibility(declaration, visible = nil)
      visible = declaration[:visible] if visible.nil? && declaration
      visible_option(visible)
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

    # The predicates .define_predicates has defined, e.g. `:has_exact_rows?`.
    # @api private
    # @return [Array<Symbol>]
    def self.predicate_names
      @predicate_names ||= []
    end

    # Defines `has_declared_<elements>?`, `has_exact_<elements>?` and their
    # `has_no_` forms on +base+. Each takes `only:`, `except:`, `visible:` and `wait:`.
    # @api private
    def self.define_predicates(base, elements)
      { declared: false, exact: true }.each do |kind, exact|
        { has: true, has_no: false }.each do |prefix, expected|
          name = :"#{prefix}_#{kind}_#{elements}?"
          predicate_names << name
          base.define_method(name) { |**options| declared_match?(expected, exact: exact, **options) }
        end
      end
    end

    module ClassMethods
      # The declarations of this class and its superclasses, in declaration
      # order. A subclass adds to its own copy.
      # @return [Hash{String => Hash}] name => `{ label: }`, with `type:` for
      #   filters and fields, `kind:` for fields, and `visible:` when the
      #   declaration gives it
      def declarations
        inherited = superclass.respond_to?(:declarations) ? superclass.declarations : {}
        inherited.merge(own_declarations).freeze
      end

      private

      def declare(name, label, visible: nil, **options)
        options[:visible] = visible unless visible.nil?
        own_declarations[ActiveAdminPageObjects.slug(name)] = { label: label.to_s, **options }.freeze
      end

      # Declares +name+ with its section class, for the class method +macro+.
      def declare_typed(macro, name, label, type:, **options)
        raise ArgumentError, "`#{macro} #{name.inspect}` needs a section class, got #{type.inspect}" unless type.is_a?(Class)

        declare(name, label, type: type, **options)
      end

      def own_declarations
        @own_declarations ||= {}
      end
    end

    # The declared names whose label on the page differs from the declaration,
    # each with the label found, or nil when the page has no such element.
    # Empty when every declared label matches. +only+ and +except+ narrow the
    # declared names that are compared. +visible+ is Capybara's option, for
    # every element.
    # @raise [ArgumentError] when the section declares nothing, for a name
    #   that is not declared, or when no declared name is in scope
    # @return [Hash{String => String, nil}]
    def declared_label_mismatches(only: nil, except: nil, visible: nil)
      declarations_in_scope(only, except).each_with_object({}) do |(name, declaration), mismatches|
        actual = declared_label_text(name, declaration, **Declarations.visibility(declaration, visible))
        mismatches[name] = actual unless actual == declaration[:label]
      end
    end

    # What keeps the page from matching the declarations exactly: the declared
    # names the page lacks, the elements on the page that are not declared, and
    # the labels that differ. With +only+ nothing is unexpected. +visible+ is
    # Capybara's option, for every element.
    # @raise [ArgumentError] as #declared_label_mismatches does
    # @return [Hash] `{ missing: [name], unexpected: [key], labels: { name => label found } }`
    def exact_mismatches(only: nil, except: nil, visible: nil)
      mismatches(true, only: only, except: except, visible: visible)
    end

    # What the last `has_declared_*?` or `has_exact_*?` call found on its last
    # try, as #exact_mismatches returns it, or nil before the first call. The
    # RSpec matchers build their failure message from it.
    # @return [Hash, nil]
    attr_reader :last_mismatches

    private

    # The text of +element+, found with +visibility+. A hidden element has no
    # visible text, so a lookup that takes hidden elements reads the DOM text.
    def text_of(element, visibility)
      element.text([nil, true, :visible].include?(visibility[:visible]) ? nil : :all)
    end

    def declarations_in_scope(only, except)
      raise ArgumentError, "the section declares no labels" if declarations.empty?

      names = declarations.keys
      names &= declared_names(only) if only
      names -= declared_names(except) if except
      # An empty scope would match any page.
      raise ArgumentError, "only: and except: leave no declared name to compare" if names.empty?

      declarations.slice(*names)
    end

    def declared_names(names)
      Array(names).map do |name|
        declaration_for(name)
        slug(name)
      end
    end

    # The mismatches in scope. Only +exact+ looks for elements that are not declared.
    def mismatches(exact, only: nil, except: nil, visible: nil)
      labels = declared_label_mismatches(only: only, except: except, visible: visible)
      missing, labels = labels.partition { |_name, actual| actual.nil? }
      unexpected = exact && !only ? undeclared_element_keys(visible) : []
      { missing: missing.map(&:first), unexpected: unexpected, labels: labels.to_h }
    end

    def undeclared_element_keys(visible)
      page_element_keys(**Declarations.visible_option(visible)) - declarations.keys
    end

    # Waits until the page matches the declarations in scope (+expected+ true)
    # or stops matching them. With +exact+ the page has no other element either.
    # +scope+ is `only:`, `except:` and `visible:`.
    def declared_match?(expected, exact:, wait: Capybara.default_max_wait_time, **scope)
      declarations_in_scope(scope[:only], scope[:except])
      eventually(wait: wait) do
        @last_mismatches = mismatches(exact, **scope)
        @last_mismatches.values.all?(&:empty?) == expected
      end
    end

    # The DOM text of the first element matching +css+, or nil without one.
    # `text(:all)` is the text before CSS `text-transform`, on every driver.
    def label_text(css, **visibility)
      element = first(:css, css, minimum: 0, wait: false, **visibility)
      element && squish(element.text(:all))
    end

    # The label of the formtastic wrapper +wrapper_css+: nil without the
    # wrapper, "" when it has no label. The first `label` is the input's own:
    # radio and check_boxes wrappers carry it in the legend, before the labels
    # of the choices.
    def wrapper_label_text(wrapper_css, **visibility)
      wrapper = first(:css, wrapper_css, minimum: 0, wait: false, **visibility)
      return unless wrapper

      label = wrapper.first(:css, "label", minimum: 0, wait: false, **visibility)
      label ? own_text(label) : ""
    end

    OWN_TEXT_SCRIPT = <<~JS
      (function (element) {
        var copy = element.cloneNode(true);
        copy.querySelectorAll("a, button, abbr").forEach(function (child) { child.remove(); });
        return copy.textContent;
      })(arguments[0])
    JS
    private_constant :OWN_TEXT_SCRIPT

    # The DOM text of +element+ without the links, buttons and `abbr` inside
    # it: formtastic's required marker, and controls that plugins append to
    # labels (the date range preset's "Set range"). The children are taken out
    # of a copy of the node, so a label that repeats their text keeps it.
    def own_text(element)
      squish(element.session.evaluate_script(OWN_TEXT_SCRIPT, element))
    rescue Capybara::NotSupportedByDriverError
      copy = element.native.dup
      copy.css("a, button, abbr").each(&:remove)
      squish(copy.text)
    end
  end
end
