class CreateSpreeReceivedPurchaseOrderLineItems < ActiveRecord::Migration
  def change
   create_table :spree_received_purchase_order_line_items do |t|
      t.references :purchase_order_line_item
      t.integer :quantity, default: 0
      t.datetime :received_at
      t.timestamps
    end
  end
end
