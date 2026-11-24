# frozen_string_literal: true

ActiveAdmin.register Customer do
  menu priority: 2
  config.per_page = 5
  config.comments = true

  permit_params :name, :email, :external_id, :status, :balance, :active, :category_id, :notes,
                :website, :phone, :password, :tier, :signed_on,
                channels: [], orders_attributes: [:id, :reference, :state, :quantity, :_destroy, { tags: [] }]

  scope :all, default: true
  scope(:active) { |customers| customers.where(active: true) }
  scope(:inactive) { |customers| customers.where(active: false) }

  filter :name
  filter :email
  filter :external_id
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

  batch_action :set_status, form: { status: Customer::STATUSES } do |ids, inputs|
    redirect_to collection_path, notice: "Set #{inputs['status']} on #{ids.size} customers"
  end

  action_item :report, only: :index do
    link_to "Report", report_admin_customers_path, class: "action-item-button"
  end

  action_item :more, only: :show do
    dropdown_menu "More" do
      item "Report", report_admin_customers_path
      item "Customers", admin_customers_path
    end
  end

  sidebar "Help", only: :index do
    para "Use the filters to narrow the list."
    ul do
      li link_to("Report", report_admin_customers_path)
      li link_to("Active customers", admin_customers_path(scope: "active"))
      li link_to("Top", "#")
    end
  end

  sidebar "Summary", only: :show do
    para "Orders: #{resource.orders.count}"
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
    column :external_id
    column(:status) { |customer| status_tag(customer.status) }
    column :balance
    column :active
    column :category
    column "Created", :created_at
    column :notes if params[:with_notes]
    actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :external_id
      row(:status) { |customer| status_tag(customer.status) }
      row :balance
      row :category
      row "Signed up", &:created_at
    end
    panel "Notes" do
      para resource.notes
    end
    tabs do
      tab "Overview" do
        para "Overview body"
      end
      tab "Orders" do
        table_for resource.orders do
          column :reference
          column :state
        end
      end
    end
    active_admin_comments
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name, as: :string
      f.input :email, as: :email
      f.input :external_id, as: :string
      f.input :status, as: :select, collection: Customer::STATUSES, input_html: { "aria-hidden": params[:aria_hidden_status] }
      f.input :category, as: :select
      f.input :balance, as: :number
      f.input :active, as: :boolean
      f.input :notes, as: :text
      f.input :website, as: :url
      f.input :phone, as: :phone
      f.input :password, as: :password
      f.input :tier, as: :radio, collection: Customer::TIERS
      f.input :channels, as: :check_boxes, collection: Customer::CHANNELS
      f.input :signed_on, as: :datepicker
    end
    f.has_many :orders, heading: "Orders", allow_destroy: true do |o|
      # A check_boxes input first: its hidden input is named `...[tags][]`.
      o.input :tags, as: :check_boxes, collection: %w[Gift Rush] if f.object.external_id == "ORDER-TAGS"
      o.input :reference
      o.input :state, as: :select, collection: Order::STATES
      o.input :quantity, input_html: { disabled: params[:lock_quantity].present? }
    end
    f.actions
  end
end
