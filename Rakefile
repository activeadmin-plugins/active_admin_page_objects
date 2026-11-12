# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Build the dummy app's Tailwind CSS with the npm CLI"
task :assets do
  Dir.chdir("spec/dummy") do
    sh "npm #{ENV['CI'] ? 'ci' : 'install'} --no-audit --no-fund" unless Dir.exist?("node_modules")
    sh "npm run build"
  end
end

task spec: :assets
task default: %i[rubocop spec]
