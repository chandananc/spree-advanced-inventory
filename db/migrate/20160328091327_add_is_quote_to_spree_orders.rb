class AddIsQuoteToSpreeOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :is_quote, :boolean, default: false
    add_column :spree_inventory_units, :is_quote, :boolean, default: false
  end
end
