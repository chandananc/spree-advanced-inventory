class CreateSpreePurchaseOrders < ActiveRecord::Migration
  def change
   create_table :spree_purchase_orders do |t|
      t.belongs_to :supplier
      t.belongs_to :supplier_contact
      t.belongs_to :user
      t.belongs_to :address
      t.belongs_to :shipping_method
      t.belongs_to :order
      t.boolean :dropship
      t.datetime :due_at
      t.decimal :discount
      t.decimal :shipping
      t.decimal :deposit
      t.text :comments
      t.text :status
      t.text :number
      t.text :terms

      t.timestamps
    end

    add_index :spree_purchase_orders, :number
    add_index :spree_purchase_orders, :status
    add_index :spree_purchase_orders, :supplier_id
    add_index :spree_purchase_orders, :supplier_contact_id
    add_index :spree_purchase_orders, :address_id
    add_index :spree_purchase_orders, :order_id
  end
end
