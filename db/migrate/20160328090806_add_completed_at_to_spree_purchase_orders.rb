class AddCompletedAtToSpreePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :spree_purchase_orders, :completed_at, :datetime, default: nil
    add_index :spree_purchase_orders, :completed_at
  end
end
