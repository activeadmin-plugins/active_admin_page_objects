# frozen_string_literal: true

module ActiveAdminPageObjects
  class Error < StandardError; end

  # The detected (or configured) ActiveAdmin markup has no page objects yet.
  class UnsupportedMarkup < Error; end

  # The page object drives a feature that ActiveAdmin 4 no longer renders.
  class RemovedInActiveAdmin4 < Error; end

  # A plugin's page objects need another version of this gem.
  class IncompatibleVersion < Error; end

  # The method needs Tom Select, but the control is a plain <select>.
  class TomSelectRequired < Error; end
end
