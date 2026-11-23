# frozen_string_literal: true

module DummyData
  def create_category(name = "Retail")
    Category.create!(name: name)
  end

  def create_customer(**attrs)
    @customer_seq = (@customer_seq || 0) + 1
    Customer.create!(
      name: "Customer #{@customer_seq}",
      email: "customer#{@customer_seq}@example.com",
      status: "active",
      balance: 10,
      **attrs
    )
  end

  def create_document(**attrs)
    Document.create!(name: "Contract", state: "draft", **attrs)
  end

  def create_customers(count, **options)
    Array.new(count) { create_customer(**options) }
  end
end
