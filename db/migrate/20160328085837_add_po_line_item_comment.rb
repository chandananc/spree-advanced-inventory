class AddPoLineItemComment < ActiveRecord::Migration
  def change
    def up
    add_column :spree_purchase_order_line_items, :comment, :string
    end

  def down
    remove_column :spree_purchase_order_line_items, :comment
  end
  end
end
