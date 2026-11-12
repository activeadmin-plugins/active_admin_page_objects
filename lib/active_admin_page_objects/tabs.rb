# frozen_string_literal: true

module ActiveAdminPageObjects
  # The `tabs` component. ActiveAdmin 4 removed it, so finding this section
  # raises RemovedInActiveAdmin4 on stock ActiveAdmin 4.
  class Tabs < Section
    selector_key :tabs
  end
end
