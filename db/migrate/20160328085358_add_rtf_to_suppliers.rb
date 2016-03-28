class AddRtfToSuppliers < ActiveRecord::Migration
  def change
    add_column  :spree_suppliers, :rtf_template, :text
  end
end
