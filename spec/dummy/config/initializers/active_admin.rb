# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.site_title = "Page Objects Dummy"
  # No Devise: a fake signed-in user fills the user menu.
  config.authentication_method = false
  config.current_user_method = :current_admin_user
  config.logout_link_path = "/admin"
  config.comments = false
  config.batch_actions = true
end

# Tom Select drives the order filters, as in apps that add it on top of stock
# ActiveAdmin; app/views/active_admin/_html_head.html.erb imports it.
ActiveAdmin.importmap.pin "tom-select", to: "js/tom-select.complete.min.js"
ActiveAdmin.importmap.pin "dummy", to: "dummy.js"
