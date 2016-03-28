class CreateSpreeSuppliers < ActiveRecord::Migration
  def change
    create_table :spree_suppliers do |t|
      t.string :name
      t.string :abbreviation
      t.string :account_number
      t.string :nr_account_number
      t.string :email
      t.string :url
      t.string :phone
      t.string :intl_phone
      t.string :fax
      t.string :intl_fax
      t.string :address1
      t.string :address2
      t.string :address3
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.text :comments

      t.timestamps
    end
  end
end
