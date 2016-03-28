Deface::Override.new(
  virtual_path: 'spree/admin/shared/_configuration_menu',
  name: 'add_advanced_inventory_settings_admin_menu_link',
  insert_bottom: "[data-hook='admin_configurations_sidebar_menu']",
  text: %q{ <%= configurations_sidebar_menu_item 'Advanced Inventory', admin_advanced_inventory_settings_path %> }
)
