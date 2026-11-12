# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "active_admin_page_objects"
require "capybara/rspec"
require "capybara/cuprite"

Capybara.app = Dummy::Application
Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1400, 900],
    headless: true,
    js_errors: true,
    # CI runners need --no-sandbox, and a small /dev/shm crashes Chrome
    # unless --disable-dev-shm-usage is set.
    browser_options: { "no-sandbox" => nil, "disable-dev-shm-usage" => nil, "disable-gpu" => nil },
    process_timeout: 30
  )
end
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

Dir[File.join(__dir__, "support/**/*.rb")].each { |file| require file }

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers
  config.include Capybara::DSL
  config.include DummyData

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"

  config.before do |example|
    Capybara.current_driver = example.metadata[:driver] || Capybara.default_driver
    [Order, Customer, Category, Tag].each(&:delete_all)
  end

  config.after do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
