class AddAutoCaptureToSpreePurchaseOrders < ActiveRecord::Migration
  def change
    add_column :spree_purchase_orders, :auto_capture_orders, :boolean, default: false
  end
end
