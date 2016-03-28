module Spree
  module Admin
    class SupplierContactsController < ResourceController
      before_filter :load_data, only: [:new, :create, :edit, :update, :destroy]

      def index
        if request.env["HTTP_REFERER"] =~ /update/
          redirect_to edit_admin_supplier_path(request.env["HTTP_REFERER"].split(/\//).last), success: "Supplier Contact Updated"
        else
          redirect_to admin_suppliers_path, success: "Supplier Contact removed"
        end
      end

      def destroy
        @supplier_contact = Spree::SupplierContact.find(params[:id])
        @supplier = @supplier_contact.supplier
        if @supplier.supplier_contacts.size > 1

          if @supplier_contact.destroy
            flash[:success] = "Contact removed"
          else
            flash[:notice] = "Could not remove that contact"
          end

        else
          flash[:error] = "Cannot remove the last contact.  Please add a new one first."
        end

        redirect_to edit_admin_supplier_url(@supplier)
      end

      def load_data
        @supplier_contact = (params[:id] ?
                             Spree::SupplierContact.find(params[:id]) :
                             Spree::SupplierContact.new)

        @supplier = @supplier_contact.supplier
      end
    end
  end
end

