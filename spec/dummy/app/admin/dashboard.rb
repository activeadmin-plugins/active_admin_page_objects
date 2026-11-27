# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    panel "Welcome" do
      para "Hello from the dashboard."
      ul do
        li a("Customers", href: admin_customers_path)
        li a("Docs", href: "https://example.com/docs")
      end
    end
    panel "Stats" do
      para "Nothing yet."
    end
    panel "Overview" do
      panel "Inner stats" do
        para "Nested."
      end
    end
  end
end
