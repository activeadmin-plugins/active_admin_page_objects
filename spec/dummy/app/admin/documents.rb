# frozen_string_literal: true

# Not in the menu. It holds what the customer pages cannot take without
# changing their declared elements: a file input, disabled inputs, two status
# tags in one cell, and titles with a count.
ActiveAdmin.register Document do
  menu false
  permit_params :name, :attachment, :state, :kind, :code, :archived

  filter :name

  sidebar "Versions (2)", only: :show do
    para "Two versions."
  end

  index do
    id_column
    column :name
    column(:flags) do |document|
      status_tag(document.state)
      status_tag("archived", class: "warning") if document.archived
    end
  end

  show do
    attributes_table do
      row :name
      row :attachment_name
      row(:flags) do |document|
        status_tag(document.state)
        status_tag("archived", class: "warning") if document.archived
      end
    end
    panel "Possible Routes (2)" do
      para "Two routes."
    end
    tabs do
      tab "Details" do
        para "Details body"
      end
      tab "Files (3)" do
        para "Three files."
      end
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
