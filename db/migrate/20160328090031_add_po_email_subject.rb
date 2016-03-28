class AddPoEmailSubject < ActiveRecord::Migration
  def up
    add_column :spree_purchase_orders, :email_subject, :string
  end

  def down
    remove_column :spree_purchase_orders, :email_subject
  end
end
