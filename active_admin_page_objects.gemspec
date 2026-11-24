# frozen_string_literal: true

require_relative "lib/active_admin_page_objects/version"

Gem::Specification.new do |spec|
  spec.name = "active_admin_page_objects"
  spec.version = ActiveAdminPageObjects::VERSION
  spec.authors = ["Denis Talakevich"]
  spec.email = ["senid231@gmail.com"]

  spec.summary = "A Page Object Model DSL for Capybara of ActiveAdmin, built on SitePrism."
  spec.description = "SitePrism pages and sections for vanilla ActiveAdmin 4's layout, index tables, filters, " \
                     "scopes, batch actions, show pages and forms, so system specs call semantic methods " \
                     "instead of CSS selectors."
  spec.homepage = "https://github.com/senid231/active_admin_page_objects"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "README.md", "CHANGELOG.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activeadmin", ">= 4.0.0.beta1", "< 5.0.0.a"
  spec.add_dependency "capybara", ">= 3.37"
  spec.add_dependency "site_prism", ">= 5.0", "< 7"
end
