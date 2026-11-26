# frozen_string_literal: true

ActiveAdmin.register Category do
  menu parent: "Catalog"
  permit_params :name

  filter :name
  filter :name_eq, label: "Exact name"
  filter :id_eq, label: "Category ID"
end
