class CreateOrderPurchaseOrders < ActiveRecord::Migration
  def change
       create_table :spree_order_purchase_orders do |t|
      t.references :order
      t.references :purchase_order
      t.timestamps
    end
    end
  end
end
