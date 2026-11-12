# frozen_string_literal: true

ActiveAdmin.register Customer do
  menu priority: 2
  config.per_page = 5

  permit_params :name, :email, :status, :balance, :active, :category_id, :notes

  scope :all, default: true
  scope(:active) { |customers| customers.where(active: true) }
  scope(:inactive) { |customers| customers.where(active: false) }

  filter :name
  filter :email
  filter :balance
  filter :status, as: :select, collection: Customer::STATUSES
  filter :category
  filter :active
  filter :created_at

  batch_action :flag do |ids|
    redirect_to collection_path, notice: "Flagged #{ids.size} customers"
  end

  batch_action :archive, confirm: "Archive the selected customers?" do |ids|
    redirect_to collection_path, notice: "Archived #{ids.size} customers"
  end

  action_item :report, only: :index do
    link_to "Report", report_admin_customers_path, class: "action-item-button"
  end

  collection_action :report do
    flash[:alert] = "Report is not ready"
    flash[:error] = "Report failed"
    redirect_to collection_path
  end

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :status
    column :balance
    column :active
    column :category
    column "Created", :created_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :status
      row :balance
      row :category
      row "Signed up", &:created_at
    end
    panel "Notes" do
      para resource.notes
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :email
      f.input :status, as: :select, collection: Customer::STATUSES
      f.input :category
      f.input :balance
      f.input :active
      f.input :notes
    end
    f.actions
  end
end
