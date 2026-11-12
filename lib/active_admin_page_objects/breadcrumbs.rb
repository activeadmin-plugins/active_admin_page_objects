# frozen_string_literal: true

module ActiveAdminPageObjects
  # The breadcrumb trail above the page title.
  class Breadcrumbs < Section
    selector_key :breadcrumbs

    elements :links, :active_admin, :breadcrumb_link

    # The breadcrumb labels in document order.
    # @return [Array<String>]
    def labels
      links.map { |link| link.text.strip }
    end

    # True when the trail shows exactly +expected+ labels, in order.
    def has_labels?(*expected, **options)
      has_links?(count: expected.size, **options) && labels_match?(expected)
    end

    # Waits for the trail to differ from +expected+.
    def has_no_labels?(*expected, **options)
      eventually(**options) { !labels_match?(expected) }
    end

    private

    def labels_match?(expected)
      actual = labels
      actual.size == expected.size && actual.zip(expected).all? { |a, e| same_text?(a, e) }
    end
  end
end
