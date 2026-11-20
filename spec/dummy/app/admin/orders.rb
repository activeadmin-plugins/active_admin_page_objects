# frozen_string_literal: true

ActiveAdmin.register Order do
  menu parent: "Catalog"

  filter :reference
  filter :quantity
  filter :customer
  filter :state, as: :select, collection: Order::STATES

  index do
    id_column
    column :reference
    column :state
    column :quantity
    column :customer
  end
end
