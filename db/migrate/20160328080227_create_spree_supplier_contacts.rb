class CreateSpreeSupplierContacts < ActiveRecord::Migration
  def change
     create_table :spree_supplier_contacts do |t|
      t.references :supplier
      t.string :name
      t.string :email
      t.string :job_title
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
    add_index :spree_supplier_contacts, :supplier_id
  end
end
