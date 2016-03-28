class AddPurchaseOrderIdToSpreeOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :purchase_order_id, :integer, default: nil
  end
end
