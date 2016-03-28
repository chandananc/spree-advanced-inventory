Deface::Override.new(
  virtual_path: "spree/products/_cart_form",
  name: "replace_product_cart_form_variant_code",
  replace: "code:contains('has_checked = false')",
  partial: "spree/products/cart_form_variant_selector"
)
