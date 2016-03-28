class AddIsDropshipToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :is_dropship, :boolean, default: false
    add_column :spree_inventory_units, :is_dropship, :boolean, default: false
  end
end
