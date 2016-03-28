class AddInventoryAdjustedToSpreeOrders < ActiveRecord::Migration
  def change
     add_column :spree_orders, :inventory_adjusted, :boolean, default: false
  end
end
