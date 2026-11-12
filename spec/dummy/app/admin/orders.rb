# frozen_string_literal: true

# The filters get Tom Select from app/javascript/dummy.js.
ActiveAdmin.register Order do
  menu parent: "Catalog"

  filter :reference
  filter :quantity
  filter :customer
  filter :state, as: :select, collection: Order::STATES, input_html: { data: { create: "true" } }

  index do
    id_column
    column :reference
    column :state
    column :quantity
    column :customer
  end
end
