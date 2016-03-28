Deface::Override.new(
  virtual_path: "spree/admin/orders/_form",
  insert_top: "[data-hook='admin-order-edit-slug']",
  name: "add_is_dropship_field_to_admin_order_details",
  partial: "spree/admin/orders/is_dropship_field")
