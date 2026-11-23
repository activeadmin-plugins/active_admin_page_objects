# frozen_string_literal: true

module HiddenElements
  # Hides every element matching +css+, as a script of the page would. Needs a JavaScript driver.
  def hide(css)
    page.execute_script("document.querySelectorAll(arguments[0]).forEach((node) => { node.style.display = 'none' })", css)
  end
end

RSpec.configure { |config| config.include HiddenElements }
