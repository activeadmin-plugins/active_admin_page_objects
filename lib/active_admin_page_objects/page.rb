# frozen_string_literal: true

module ActiveAdminPageObjects
  # A page rendered in the ActiveAdmin layout. Subclass it and add sections.
  class Page < SitePrism::Page
    include Layout
  end
end
