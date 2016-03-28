module Spree
  module Admin
    class SuppliersController < ResourceController
      before_filter :copy_rtf, only: [:create, :update]
      before_filter :setup_new_supplier_contact, only: [:new, :edit]
      before_filter :setup_entered_supplier_contact, only: [:create, :update]

      def index
        params[:q] ||= {}

        @search = Spree::Supplier.accessible_by(current_ability, :index).ransack(params[:q])
        @suppliers = @search.result.includes([:supplier_contacts]).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page]).
          order("spree_suppliers.name asc")

        respond_with(@suppliers)        
      end

      def pricing_for_variant
        @variant = Spree::Variant.find(params[:variant_id])

        @suppliers = @variant.suppliers

        render layout: !request.xhr?
      end

      def copy_rtf
        if params["rtf_template"]
          params[:supplier] = { rtf_template: "" }

          params["rtf_template"].tempfile.each_line do |l|
            params[:supplier][:rtf_template] += l
          end
        end
      end 

      def create
        @supplier = Spree::Supplier.new(params[:supplier])
        
        if @new_supplier_contact 
          @new_supplier_contact.supplier = @supplier
        end
        
        if @supplier.valid? and @new_supplier_contact and @new_supplier_contact.valid?
          @supplier.save
          flash[:success] = "Supplier and contact saved"
          redirect_to edit_admin_supplier_url(@supplier)
        else
          logger.info @supplier.valid?
          logger.info @new_supplier_contact.will_save?
          render "new"
        end
      end

      def update
        if @new_supplier_contact and @new_supplier_contact.will_save? and @new_supplier_contact.valid? and @supplier.update_attributes(params[:supplier])
          @new_supplier_contact.save
          flash[:success] = "Supplier updated and contact created"
          redirect_to edit_admin_supplier_url(@supplier)
        elsif (not @new_supplier_contact or not @new_supplier_contact.will_save?) and @supplier.update_attributes(params[:supplier])
          flash[:success] = "Supplier updated"
          redirect_to edit_admin_supplier_url(@supplier)
        else
          render "edit"
        end
      end

      def setup_new_supplier_contact
        @new_supplier_contact = Spree::SupplierContact.new

        if @supplier
          @new_supplier_contact.supplier = @supplier
        end
      end

      def setup_entered_supplier_contact
        if params[:supplier] and 
          params[:supplier][:supplier_contacts_attributes] and 
          params[:supplier][:supplier_contacts_attributes]["0"]

          @new_supplier_contact = Spree::SupplierContact.new(params[:supplier][:supplier_contacts_attributes]["0"])
        else
          setup_new_supplier_contact
        end

        @new_supplier_contact.valid?
      end

    end
  end
end
