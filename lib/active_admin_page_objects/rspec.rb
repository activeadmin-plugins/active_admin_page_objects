# frozen_string_literal: true

require "rspec/expectations"
require "active_admin_page_objects"

module ActiveAdminPageObjects
  # RSpec matchers for the page objects. Include the module after
  # capybara_active_admin's matchers, when the suite uses that gem, so it takes
  # precedence:
  #
  #   RSpec.configure do |config|
  #     config.include Capybara::ActiveAdmin::TestHelpers, type: :system
  #     config.include ActiveAdminPageObjects::RSpec::Matchers
  #   end
  module RSpec
    # Base of the matchers with a detailed failure message. It asks the
    # section the predicate of the same name, as RSpec's predicate matcher
    # does, and a subclass describes what the predicate found. On an object
    # that is not such a section it is RSpec's predicate matcher.
    class DetailedMatcher
      include ::RSpec::Matchers::Composable

      # +_other+ is the matcher of the same name of another module: unused here.
      def initialize(name, _other, *args, **options, &block)
        @name = name
        @args = args
        @options = options
        @block = block
      end

      def matches?(actual)
        return ask(actual, @name) if detailed?(actual)

        (@fallback = predicate_matcher).matches?(actual)
      end

      # Asks the opposite predicate, which waits: `not_to have_exact_rows` asks `has_no_exact_rows?`.
      def does_not_match?(actual)
        return ask(actual, opposite) if detailed?(actual)

        (@fallback = predicate_matcher).does_not_match?(actual)
      end

      def failure_message
        @fallback ? @fallback.failure_message : message
      end

      def failure_message_when_negated
        @fallback ? @fallback.failure_message_when_negated : message
      end

      def description
        predicate_matcher.description
      end

      private

      def detailed?(actual)
        actual.is_a?(self.class::SECTION) && actual.respond_to?(predicate(@name))
      end

      def predicate(name)
        :"#{name.to_s.sub('have_', 'has_')}?"
      end

      def opposite
        negative?(@name) ? @name.to_s.sub("have_no_", "have_").to_sym : @name.to_s.sub("have_", "have_no_").to_sym
      end

      def negative?(name)
        name.start_with?("have_no_")
      end

      def predicate_matcher
        ::RSpec::Matchers::BuiltIn::Has.new(@name, *@args, **@options, &@block)
      end

      # Keeps what the predicate found: a later call on the section replaces it.
      def ask(actual, name)
        @asked = name
        result = actual.public_send(predicate(name), *@args, **@options, &@block)
        record(actual)
        result
      end

      def message
        negative?(@asked) ? negative_message : positive_message
      end

      def quoted(texts)
        texts.map(&:inspect).join(", ")
      end

      # The items of +list+ that +other+ lacks, counting repeated items.
      def lacking(list, other)
        other = other.dup
        list.reject { |item| (index = other.index(item)) && other.delete_at(index) }
      end
    end

    # `have_exact_rows`, `have_no_declared_fields` and the like. Its failure
    # message lists the missing and the unexpected elements and the labels
    # that differ.
    class DeclaredMatcher < DetailedMatcher
      SECTION = Declarations
      SCOPE_OPTIONS = %i[only except visible].freeze

      def description
        "#{@name.to_s.tr('_', ' ')}#{scope}"
      end

      private

      def record(actual)
        @declarations = actual.class.declarations
        @mismatches = actual.last_mismatches
      end

      def exact?
        @asked.to_s.include?("_exact_")
      end

      def kind
        @asked.to_s.split("_").last
      end

      def positive_message
        expected = exact? ? "exactly the declared #{kind}" : "the declared #{kind}"
        "expected #{expected}#{scope}, but:\n#{differences.join("\n")}"
      end

      def negative_message
        return "expected the #{kind} to differ from the declared ones#{scope}, but they match exactly" if exact?

        "expected a declared #{kind.delete_suffix('s')} to be missing or to have another label#{scope}, but every one matches"
      end

      def differences
        lines = %i[missing unexpected].filter_map do |key|
          "  #{key}: #{@mismatches[key].join(', ')}" unless @mismatches[key].empty?
        end
        lines + @mismatches[:labels].map do |name, found|
          "  label of #{name}: expected #{@declarations[name][:label].inspect}, got #{found.inspect}"
        end
      end

      # The options that narrow the comparison, e.g. " (only: name, email)".
      def scope
        given = SCOPE_OPTIONS.select { |option| @options.key?(option) }
        return "" if given.empty?

        " (#{given.map { |option| "#{option}: #{Array(@options[option]).join(', ')}" }.join('; ')})"
      end
    end

    # `have_exact_field_errors` and `have_no_exact_field_errors`. Its failure
    # message lists, per field, the messages that are missing and the ones
    # that were not expected.
    class FieldErrorsMatcher < DetailedMatcher
      SECTION = Fields

      private

      attr_reader :expected

      def record(actual)
        @shown = actual.last_field_errors
        @expected = actual.field_error_expectation(@options)
      end

      def positive_message
        header = expected.empty? ? "expected no field errors" : "expected exactly the given field errors"
        "#{header}, but:\n#{differences.join("\n")}"
      end

      def negative_message
        return "expected a field error, but no field shows one" if expected.empty?

        "expected the field errors to differ from the given ones, but they match exactly"
      end

      def differences
        (expected.keys | @shown.keys).filter_map { |name| difference(name, expected.fetch(name, []), @shown.fetch(name, [])) }
      end

      # The line of one field, or nil when it shows what is expected.
      def difference(name, wanted, shown)
        parts = { missing: lacking(wanted, shown), unexpected: lacking(shown, wanted) }.reject { |_kind, texts| texts.empty? }
        "  #{name}: #{parts.map { |kind, texts| "#{kind} #{quoted(texts)}" }.join('; ')}" unless parts.empty?
      end
    end

    # `have_exact_semantic_errors` and `have_no_exact_semantic_errors`. Its
    # failure message lists the missing and the unexpected base errors, or
    # both orders when only the order differs.
    class SemanticErrorsMatcher < DetailedMatcher
      SECTION = Form

      private

      attr_reader :expected

      def record(actual)
        @shown = actual.last_semantic_errors
        @expected = actual.semantic_error_expectation(@args)
      end

      def positive_message
        return "expected no semantic errors, but:\n#{differences.join("\n")}" if expected.empty?

        order = @options[:strict_order] ? ", in order" : ""
        "expected exactly the given semantic errors#{order}, but:\n#{differences.join("\n")}"
      end

      def negative_message
        return "expected a semantic error, but the form shows none" if expected.empty?

        "expected the semantic errors to differ from the given ones, but they match exactly"
      end

      def differences
        lines = { missing: lacking(expected, @shown), unexpected: lacking(@shown, expected) }.filter_map do |kind, texts|
          "  #{kind}: #{quoted(texts)}" unless texts.empty?
        end
        lines.empty? ? ["  order: expected #{quoted(expected)}, got #{quoted(@shown)}"] : lines
      end
    end

    # Picks the matcher when it sees what the expectation is about: RSpec's
    # predicate matcher for a page object that has the predicate, or else the
    # matcher of the same name of the module included before.
    class Matcher
      include ::RSpec::Matchers::Composable

      # Capybara's own `has_table?` reaches a page through Capybara::DSL and a
      # section through SitePrism::Section, which delegates to its root element.
      CAPYBARA_OWNERS = [Capybara::DSL, SitePrism::Section].freeze

      def initialize(name, other, *args, **options, &block)
        @name = name
        @other = other
        @args = args
        @options = options
        @block = block
      end

      def matches?(actual)
        @negated = false
        @matcher = page_object?(actual) || @other.nil? ? predicate_matcher(@name) : @other.call
        @matcher.matches?(actual)
      end

      # A page object that has `has_no_<name>?` is asked that, as SitePrism does:
      # the predicate waits for the content to go away.
      def does_not_match?(actual)
        return other_does_not_match?(actual) unless page_object?(actual) || @other.nil?

        @negated = actual.respond_to?(:"has_no_#{root}?")
        return (@matcher = predicate_matcher(:"have_no_#{root}")).matches?(actual) if @negated

        (@matcher = predicate_matcher(@name)).does_not_match?(actual)
      end

      def failure_message
        @matcher.failure_message
      end

      def failure_message_when_negated
        @negated ? @matcher.failure_message : @matcher.failure_message_when_negated
      end

      def description
        (@matcher || predicate_matcher(@name)).description
      end

      private

      def root
        @name.to_s.delete_prefix("have_")
      end

      # True for a SitePrism page or section that defines the predicate
      # itself, as `section :table` does. A predicate it only has from
      # Capybara is not a page-object predicate.
      def page_object?(actual)
        predicate = :"has_#{root}?"
        return false unless actual.is_a?(SitePrism::Page) || actual.is_a?(SitePrism::Section)

        actual.respond_to?(predicate) && !CAPYBARA_OWNERS.include?(actual.method(predicate).owner)
      end

      def predicate_matcher(name)
        ::RSpec::Matchers::BuiltIn::Has.new(name, *@args, **@options, &@block)
      end

      def other_does_not_match?(actual)
        @negated = false
        @matcher = @other.call
        @matcher.respond_to?(:does_not_match?) ? @matcher.does_not_match?(actual) : !@matcher.matches?(actual)
      end
    end

    # `have_declared_rows`, `have_exact_fields`, `have_exact_field_errors` and
    # the like, with a failure message that lists what differs: see
    # DeclaredMatcher, FieldErrorsMatcher and SemanticErrorsMatcher.
    #
    # And `have_<name>` for every matcher capybara_active_admin 1.0.0 defines,
    # so page objects and that gem share the names. On a SitePrism page or
    # section that has the predicate, it is RSpec's predicate matcher:
    # `expect(index).to have_page_title(text: "Customers")`. On anything else
    # it is the matcher of the module included before this one.
    module Matchers
      # The matcher names of capybara_active_admin 1.0.0.
      NAMES = %i[
        have_action_item have_action_item_link have_attribute_row have_attributes_table have_batch_action
        have_fields_date_range have_flash_message have_footer have_form_error have_has_many_fields_for
        have_no_form_errors have_page_title have_panel have_semantic_error have_semantic_errors have_sidebar
        have_status_tag have_submit_input have_table have_table_cell have_table_header have_table_row
        have_table_scope have_table_scopes
      ].freeze

      DECLARED_NAMES = Declarations.predicate_names.map { |name| :"#{name.to_s.sub('has_', 'have_').chomp('?')}" }.freeze

      ERROR_MATCHERS = {
        have_exact_field_errors: FieldErrorsMatcher,
        have_no_exact_field_errors: FieldErrorsMatcher,
        have_exact_semantic_errors: SemanticErrorsMatcher,
        have_no_exact_semantic_errors: SemanticErrorsMatcher
      }.freeze

      # Matcher name => matcher class.
      MATCHERS = {
        **NAMES.to_h { |name| [name, Matcher] },
        **DECLARED_NAMES.to_h { |name| [name, DeclaredMatcher] },
        **ERROR_MATCHERS
      }.freeze

      MATCHERS.each do |name, matcher|
        define_method(name) do |*args, **options, &block|
          # The other matcher is built when it is needed: its signature may not take a page object's arguments.
          other = defined?(super) ? -> { super(*args, **options, &block) } : nil
          matcher.new(name, other, *args, **options, &block)
        end
      end
    end
  end
end
