# frozen_string_literal: true

ActiveAdmin.register Category do
  menu parent: "Catalog"
  permit_params :name

  filter :name
end
