Deface::Override.new(
  virtual_path: "spree/admin/orders/index",
  replace: "li#admin-new-order-button",
  name: "replace-admin-order-button",
  partial: "spree/admin/orders/new_order_button"
)

Deface::Override.new(
  virtual_path: "spree/admin/orders/index",
  insert_before: "[data-hook='admin_orders_index_search']",
  name: "add_order_button_menu",
  partial: "spree/admin/orders/quote_order_button")

Deface::Override.new(
  virtual_path: "spree/admin/shared/_order_tabs",
  replace_contents: "code[erb-silent]:contains('content_for :page_title do')",
  closing_selector: "code[erb-silent]:contains('end')",
  partial: "spree/admin/orders/page_title",
  name: "replace-order-form-titles"
)
