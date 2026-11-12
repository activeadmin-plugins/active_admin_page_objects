# frozen_string_literal: true

module ActiveAdminPageObjects
  # The scope buttons above the index table. Scopes are found by label,
  # ignoring case and the count badge.
  class Scopes < Section
    selector_key :scopes

    # The scope labels without counts.
    # @return [Array<String>]
    def labels
      all(:active_admin, :scope).map { |link| label_of(link) }
    end

    # Clicks the scope labelled +label+.
    def select(label)
      scope_link(label).click
    end

    # True when the scope labelled +label+ is the current one.
    def has_selected?(label, **options)
      eventually(**options) { selected_label_matches?(label) }
    end

    # Waits until the scope labelled +label+ is no longer the current one.
    def has_no_selected?(label, **options)
      eventually(**options) { !selected_label_matches?(label) }
    end

    # The count badge of the scope labelled +label+, or nil without one.
    # @return [Integer, nil]
    def count(label)
      badge = scope_link(label).first(:active_admin, :scope_count, minimum: 0)
      badge && Integer(badge.text.strip)
    end

    private

    def scope_link(label)
      all(:active_admin, :scope).find { |link| same_text?(label_of(link), label) } ||
        raise(Capybara::ElementNotFound, "no scope #{label.inspect} in #{labels.inspect}")
    end

    def selected_label_matches?(label)
      link = first(:active_admin, :scope_selected, minimum: 0, wait: false)
      link && same_text?(label_of(link), label)
    end

    def label_of(link)
      badge = link.first(:active_admin, :scope_count, minimum: 0, wait: false)
      text = link.text.strip
      badge ? text.delete_suffix(badge.text.strip).strip : text
    end
  end
end
