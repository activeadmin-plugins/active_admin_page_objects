# frozen_string_literal: true

# Not in the menu. It holds what the customer pages cannot take without
# changing their declared elements: a file input, disabled inputs and a
# title with a count.
ActiveAdmin.register Document do
  menu false
  permit_params :name, :attachment, :state, :kind, :code, :archived

  filter :name

  index do
    id_column
    column :name
  end

  show do
    attributes_table do
      row :name
      row :attachment_name
    end
    panel "Possible Routes (2)" do
      para "Two routes."
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :attachment, as: :file
      f.input :code, input_html: { disabled: true }
      f.input :state, as: :select, collection: Document::STATES, input_html: { disabled: true }
      f.input :kind, as: :radio, collection: Document::KINDS, input_html: { disabled: true }
      f.input :archived, as: :boolean, input_html: { disabled: true }
    end
    f.actions
  end
end
