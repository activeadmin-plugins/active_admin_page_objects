# frozen_string_literal: true

ActiveAdmin.register Order do
  menu parent: "Catalog"

  permit_params :reference, :state, :quantity, :customer_id,
                line_items_attributes: [:id, :sku, :kind, :quantity, :_destroy, { tags: [] }]

  filter :reference, filters: %i[not_eq eq]
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

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :reference
      f.input :state, as: :select, collection: Order::STATES
      f.input :quantity
      f.input :customer, as: :select
    end
    f.has_many :line_items, heading: "Line Items", allow_destroy: true do |item|
      # A check_boxes input first: its hidden input is named `...[tags][]`.
      item.input :tags, as: :check_boxes, collection: %w[Gift Rush] if f.object.reference == "LINE-TAGS"
      item.input :sku
      item.input :kind, as: :select, collection: LineItem::KINDS
      item.input :quantity
    end
    f.actions
  end
end
