Deface::Override.new(
  virtual_path: 'spree/admin/variants/_form',
  name: 'add_stock_type_to_variant_edit',
  insert_bottom: "[data-hook='admin_variant_form_additional_fields']",
  partial: "spree/admin/variants/stock_type"
)

