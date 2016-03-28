Spree::AppConfiguration.class_eval do
  preference :advanced_inventory_disable_payment_captures, :string
  preference :advanced_inventory_office_address1, :string
  preference :advanced_inventory_office_address2, :string
  preference :advanced_inventory_office_company, :string
  preference :advanced_inventory_office_phone, :string
  preference :advanced_inventory_office_email, :string
  preference :advanced_inventory_office_city, :string
  preference :advanced_inventory_office_state, :string
  preference :advanced_inventory_office_zip, :string
  preference :advanced_inventory_office_country, :string
  preference :advanced_inventory_tax_id, :string
  preference :advanced_inventory_admin_views_path, :string
end
