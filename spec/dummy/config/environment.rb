# frozen_string_literal: true

require_relative "application"

# A file, not ":memory:": each Puma thread would get its own empty database.
require "fileutils"
db_file = File.expand_path("../tmp/dummy.sqlite3", __dir__)
FileUtils.mkdir_p(File.dirname(db_file))
FileUtils.rm_f(db_file)

Dummy::Application.initialize!

require_relative "schema"
