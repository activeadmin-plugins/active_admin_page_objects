# frozen_string_literal: true

module ActiveAdminPageObjects
  class Error < StandardError; end

  # The page object drives a feature that ActiveAdmin 4 no longer renders.
  # Raised by 2.x only; defined here so code that rescues it loads on 1.x.
  class RemovedInActiveAdmin4 < Error; end

  # The page object drives a feature that ActiveAdmin 3 does not have.
  class NotInActiveAdmin3 < Error; end

  # The page has an element of another class than the declared one. Field
  # and filter lookups raise it.
  class DeclaredClassMismatch < Capybara::ExpectationNotMet; end

  # A plugin's page objects need another version of this gem.
  class IncompatibleVersion < Error; end
end
