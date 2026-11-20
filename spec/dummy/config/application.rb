# frozen_string_literal: true

# Minimal ActiveAdmin 4 host app (importmap + propshaft, Tailwind CSS built by
# the npm CLI) that the specs drive through the page objects.
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"
require "activeadmin"

module Dummy
  class Application < Rails::Application
    # Booted by requiring this file from the specs, so pin the root or Rails
    # looks for config/database.yml in the repository root.
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 8.0
    config.eager_load = false
    config.consider_all_requests_local = true
    config.secret_key_base = "dummy-secret-key-base-for-tests-only"
    config.hosts.clear
    config.action_controller.allow_forgery_protection = false
    config.logger = Logger.new($stdout)
    config.log_level = :warn
    config.public_file_server.enabled = true
  end
end
