# frozen_string_literal: true

module ActiveAdminPageObjects
  # Base section for one filter input wrapper, `#q_<key>_input`. Declare a
  # typed filter directly with its wrapper id:
  #
  #   section :name_filter, ActiveAdminPageObjects::StringFilter, "#q_name_input"
  class Filter < Section
    # The filter label text.
    # @return [String]
    def label
      find("label", match: :first).text.strip
    end
  end
end
