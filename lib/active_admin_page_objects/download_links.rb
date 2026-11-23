# frozen_string_literal: true

module ActiveAdminPageObjects
  # The download links under the index table: "Download: CSV XML JSON".
  # ActiveAdmin renders them only when the index has records. A format is
  # named by its link text, ignoring case: `"CSV"` or `:csv`.
  class DownloadLinks < Section
    selector_key :download_links

    # The link texts in page order, e.g. `["CSV", "XML", "JSON"]`.
    # @return [Array<String>]
    def formats
      links.map { |link| link.text.strip }
    end

    # The `href` attribute of the link of +format+, as the page wrote it.
    # @raise [Capybara::ElementNotFound] when there is no such link
    # @return [String]
    def href(format)
      href_attribute(link(format))
    end

    # Clicks the link of +format+.
    # @raise [Capybara::ElementNotFound] when there is no such link
    def click(format)
      link(format).click
    end

    # True when there is a link of +format+.
    def has_format?(format, **options)
      eventually(**options) { find_link(format) }
    end

    # Waits until there is no link of +format+.
    def has_no_format?(format, **options)
      eventually(**options) { find_link(format).nil? }
    end

    private

    def links
      all(:active_admin, :download_link)
    end

    def find_link(format)
      links.find { |link| same_text?(link.text, format) }
    end

    def link(format)
      find_link(format) || raise(Capybara::ElementNotFound, "no download format #{format.inspect} in #{formats.inspect}")
    end
  end
end
