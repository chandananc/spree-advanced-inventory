class AddTimeTrackingToSpreePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :spree_purchase_orders, :entered_at, :datetime, default: nil
    add_column :spree_purchase_orders, :submitted_at, :datetime, default: nil
  end
end
