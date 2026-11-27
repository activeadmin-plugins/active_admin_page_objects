# frozen_string_literal: true

module ActiveAdminPageObjects
  # The comments of a show page. Declare it on the page; the page must render
  # them, which the default show page does and a custom `show` block does not
  # until it calls `active_admin_comments_for(resource)`:
  #
  #   section :comments, ActiveAdminPageObjects::Comments
  class Comments < Section
    selector_key :comments

    # The number in the "All Comments (N)" title.
    # @return [Integer]
    def count
      find(:active_admin, :comments_title).text[/\((\d+)\)/, 1].to_i
    end

    # The comment body texts, in page order.
    # @return [Array<String>]
    def bodies
      all(:active_admin, :comment_body, wait: false).map { |el| el.text.strip }
    end

    # The comment author texts, in page order.
    # @return [Array<String>]
    def authors
      all(:active_admin, :comment_author, wait: false).map { |el| el.text.strip }
    end

    # True when a comment body contains +text+. Pass `exact_text:` for a full match.
    def has_comment?(text, **options)
      has_css?(sel(:comment_body), text: text, **options)
    end

    # Waits until no comment body contains +text+.
    def has_no_comment?(text, **options)
      has_no_css?(sel(:comment_body), text: text, **options)
    end

    # Types +text+ into the comment form and submits it.
    # @raise [Capybara::ExpectationNotMet] when the comment does not show up
    def add(text)
      find(:active_admin, :comment_input).set(text)
      find(:active_admin, :comment_submit).click
      root_element.assert_selector(:css, sel(:comment_body), text: text)
    end

    # Deletes the comment whose body contains +text+, accepting the browser confirmation.
    def delete(text)
      link = comment_for(text).find(:active_admin, :comment_delete)
      accept_confirm { link.click }
    end

    private

    def comment_for(text)
      root_element.synchronize do
        all(:active_admin, :comment, wait: false).find do |comment|
          comment.has_css?(sel(:comment_body), text: text, wait: false)
        end || raise(Capybara::ElementNotFound, "no comment containing #{text.inspect}")
      end
    end
  end
end
