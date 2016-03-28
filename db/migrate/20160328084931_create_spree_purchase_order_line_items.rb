class CreateSpreePurchaseOrderLineItems < ActiveRecord::Migration
  def change
    create_table :spree_purchase_order_line_items do |t|
      t.references :user
      t.references :purchase_order
      t.references :variant
      t.integer :quantity
      t.decimal :price

      t.timestamps
    end
    add_index :spree_purchase_order_line_items, :user_id
    add_index :spree_purchase_order_line_items, :purchase_order_id
    add_index :spree_purchase_order_line_items, :variant_id
  end
end
