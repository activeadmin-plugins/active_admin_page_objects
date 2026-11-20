# frozen_string_literal: true

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :categories do |t|
    t.string :name
  end

  create_table :customers do |t|
    t.string :name, :email, :status
    t.decimal :balance, precision: 12, scale: 2, default: 0
    t.boolean :active, default: true, null: false
    t.references :category
    t.text :notes
    t.string :external_id, :website, :phone, :tier
    t.text :channels
    t.date :signed_on
    t.timestamps
  end

  create_table :orders do |t|
    t.string :reference, :state
    t.integer :quantity
    t.references :customer
    t.timestamps
  end

  create_table :tags do |t|
    t.string :name
  end
end
