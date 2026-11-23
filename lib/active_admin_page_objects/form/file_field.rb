# frozen_string_literal: true

module ActiveAdminPageObjects
  class Form
    # A file field. `fill` attaches a file by its path.
    class FileField < Field
      # Attaches the file at +path+: a String or a Pathname. JavaScript
      # drivers need an absolute path.
      # @raise [Capybara::FileNotFound] when the path has no file
      def fill(path)
        root_element.attach_file(path.to_s)
      end
    end
  end
end
