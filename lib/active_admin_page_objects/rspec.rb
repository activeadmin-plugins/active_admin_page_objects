# frozen_string_literal: true

require "rspec/expectations"
require "active_admin_page_objects"

module ActiveAdminPageObjects
  # Lets page objects and capybara_active_admin share the matcher names that
  # gem defines. Include it after that gem's matchers, so it takes precedence:
  #
  #   RSpec.configure do |config|
  #     config.include Capybara::ActiveAdmin::TestHelpers, type: :system
  #     config.include ActiveAdminPageObjects::RSpec::Matchers
  #   end
  module RSpec
    # `have_<name>` for every matcher capybara_active_admin 1.0.0 defines. On a
    # SitePrism page or section that has the predicate, it is RSpec's predicate
    # matcher: `expect(index).to have_page_title(text: "Customers")`. On
    # anything else it is the matcher of the module included before this one.
    module Matchers
      NAMES = %i[
        have_action_item have_action_item_link have_attribute_row have_attributes_table have_batch_action
        have_fields_date_range have_flash_message have_footer have_form_error have_has_many_fields_for
        have_no_form_errors have_page_title have_panel have_semantic_error have_semantic_errors have_sidebar
        have_status_tag have_submit_input have_table have_table_cell have_table_header have_table_row
        have_table_scope have_table_scopes
      ].freeze

      NAMES.each do |name|
        define_method(name) do |*args, **options, &block|
          # The other matcher is built when it is needed: its signature may not take a page object's arguments.
          other = defined?(super) ? -> { super(*args, **options, &block) } : nil
          Matcher.new(name, other, *args, **options, &block)
        end
      end
    end

    # Picks the matcher when it sees what the expectation is about.
    class Matcher
      def initialize(name, other, *args, **options, &block)
        @name = name
        @other = other
        @args = args
        @options = options
        @block = block
      end

      def matches?(actual)
        return predicate_matcher(@name).matches?(actual) if page_object?(actual) || @other.nil?

        (@matcher = @other.call).matches?(actual)
      end

      # A page object that has `has_no_<name>?` is asked that, as SitePrism does:
      # the predicate waits for the content to go away.
      def does_not_match?(actual)
        return other_does_not_match?(actual) unless page_object?(actual) || @other.nil?

        negated = :"have_no_#{root}"
        return predicate_matcher(negated).matches?(actual) if actual.respond_to?(:"has_no_#{root}?")

        predicate_matcher(@name).does_not_match?(actual)
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

      def page_object?(actual)
        (actual.is_a?(SitePrism::Page) || actual.is_a?(SitePrism::Section)) && actual.respond_to?(:"has_#{root}?")
      end

      def predicate_matcher(name)
        @negated = name != @name
        @matcher = ::RSpec::Matchers::BuiltIn::Has.new(name, *@args, **@options, &@block)
      end

      def other_does_not_match?(actual)
        @matcher = @other.call
        @matcher.respond_to?(:does_not_match?) ? @matcher.does_not_match?(actual) : !@matcher.matches?(actual)
      end
    end
  end
end
