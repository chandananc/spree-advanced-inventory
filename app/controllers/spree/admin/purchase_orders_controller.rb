module Spree
  module Admin
    class PurchaseOrdersController < ResourceController

      respond_to :html, only: [:index, :show, :destroy]
      respond_to :json, only: [:index, :show]
      respond_to :pdf, only: [:show, :submit]
      respond_to :rtf, only: [:show, :submit]

      before_filter :remove_unused, only: [:index]
      before_filter :find_or_create_office_address
      before_filter :load_supplier, only: [:create, :update]
      before_filter :find_or_build_address, only: [:create, :update]
      before_filter :update_orders, only: [:update]
      before_filter :set_pdf_variables, only: [:show, :submit]
      
      def index
        @total_shipping = 0.0
        @total_tax = 0.0
        @total = 0.0

        session[:return_to] = request.original_url

        params[:q] ||= {}

        # As date params are deleted if @show_only_completed, store
        # the original date so we can restore them into the params
        # after the search
        created_at_gt = params[:q][:created_at_gt]
        created_at_lt = params[:q][:created_at_lt]

        if !params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if params[:q][:status_cont] == "Submitted"
          params[:q][:submitted_at_lt] = params[:q][:created_at_lt]
          params[:q][:submitted_at_gt] = params[:q][:created_at_gt]
          params[:q][:s] = "spree_purchase_orders.submitted_at desc"
          params[:q].delete(:created_at_gt)
          params[:q].delete(:created_at_lt)

        elsif params[:q][:status_cont] == "Completed"
          params[:q][:completed_at_lt] = params[:q][:created_at_lt]
          params[:q][:completed_at_gt] = params[:q][:created_at_gt]
          params[:q][:s] = "spree_purchase_orders.completed_at desc"
          params[:q].delete(:created_at_gt)
          params[:q].delete(:created_at_lt)
        elsif params[:q][:status_cont] == "Entered"
          params[:q][:entered_at_lt] = params[:q][:created_at_lt]
          params[:q][:entered_at_gt] = params[:q][:created_at_gt]
          params[:q][:s] = "spree_purchase_orders.entered_at desc"
          params[:q].delete(:created_at_gt)
          params[:q].delete(:created_at_lt)
        else
          params[:q][:s] = "spree_purchase_orders.created_at desc"
        end

        logger.info "\n\n*** #{params[:q][:s]}"

        if params[:q][:supplier_invoice_number_blank] == "true"
          @null_supplier_invoice = true
          params[:q].delete(:supplier_invoice_number_cont)
        else
          @null_supplier_invoice = false
        end

        if params[:per_page] == "All"
          params[:per] = 99999999
        end

        @search = Spree::PurchaseOrder.includes(:purchase_order_line_items, :user, :address, :variants, :orders).ransack(params[:q])
        @purchase_orders = @search.result(distinct: true).includes(:purchase_order_line_items, :user, :address, :variants, :orders).
          page(params[:page]).
          per(params[:per] || 50).
          order(params[:q][:s] + " NULLS LAST")

        # Restore dates
        params[:q][:created_at_gt] = created_at_gt
        params[:q][:created_at_lt] = created_at_lt

        respond_with(@purchase_orders, layout: !request.xhr?)
      end

      def show
        @purchase_order = find_resource
        respond_with(@purchase_order) do |format|
          format.html { render layout: !request.xhr? }
          format.json { render(json: @purchase_order) }
          format.pdf { 

            if File.exists?(@purchase_order.pdf_file_path)
              send_file(@purchase_order.pdf_file_path, type: "application/pdf", disposition: "attachment; filename=#{@purchase_order.number}.pdf")
            else
              render(:pdf     => "#{@purchase_order.number}",
                :disposition  => "attachment",
                :page_size    => "Letter",
                :layout       => "pdf",
                :type         => "application/pdf",
                :save_to_file => @purchase_order.pdf_file_path,
                :show_as_html => params[:debug].present?)
            end
          }
          format.rtf { send_data(@purchase_order.save_rtf, type: "application/rtf; charset=utf-8; header=present", disposition: "attachment; filename=#{@purchase_order.number}.rtf") }

        end
      end
      
      def set_pdf_variables
        @hide_prices = false
        @quote = false
        @line_item_class = "line-item-medium"
        @line_item_image_height = 30
        @max_line_items = 20
      end

      def purchase_order

      end

      def new
        set_type
        redirect_to admin_purchase_order_edit_line_items_path(@purchase_order.number)
      end

      def update
        @purchase_order = Spree::PurchaseOrder.find_by_number(params[:id])

        if @purchase_order.update_attributes(params[:purchase_order])
          flash[:success] = "#{@purchase_order.po_type} updated"
          
          next_url = session[:return_to]||admin_purchase_orders_url()

          if @purchase_order.resend_po == true
            @purchase_order.update_column(:status, "Entered")
          else 
            if @purchase_order.submitted_at.present?
              @purchase_order.update_column(:status, "Submitted")
            end

            if @purchase_order.completed_at.present?
              @purchase_order.update_column(:status, "Completed")
            end
          end

          if params[:submit] =~ /edit/i
            next_url = edit_admin_purchase_order_path(@purchase_order.number)
          else
            session[:return_to] = nil
          end

          if File.exists?(@purchase_order.pdf_file_path)
            File.unlink(@purchase_order.pdf_file_path)
          end

          redirect_to next_url
        else
          render action: "edit"
        end
      end

      def edit_line_items
        @purchase_order = find_resource

        if @purchase_order.status.blank?
          @purchase_order.status = "New"
          @purchase_order.save validate: false
        end
        
        total_line_items = @purchase_order.purchase_order_line_items ? @purchase_order.purchase_order_line_items.size : 0
        @tli = total_line_items
        @line_item_limit = total_line_items + (20 - total_line_items)

        1.upto(@line_item_limit).each do |num|
          @purchase_order.purchase_order_line_items.build
        end

        if request.put? or request.post?
          if params[:purchase_order][:supplier_contact_id]
            contact = Spree::SupplierContact.find(params[:purchase_order][:supplier_contact_id])

            if contact
              @purchase_order.update_column(:supplier_contact_id, contact.id)
              @purchase_order.update_column(:supplier_id, contact.supplier_id)
            end
          end

          params[:purchase_order][:purchase_order_line_items_attributes].each do |k,line_item|
            
            if line_item["variant_id"].to_i > 0 
              variant = Spree::Variant.find(line_item["variant_id"])
            end

            if variant and line_item["price"].to_f == 0.0
              if @purchase_order.supplier and @purchase_order.supplier.discounts_available?
                line_item["price"] = @purchase_order.supplier.price_at_quantity(variant, line_item["quantity"], line_item["returnable"])
              else
                line_item["price"] = variant.recent_price
              end
            end

            if line_item["id"].to_i > 0
              l = Spree::PurchaseOrderLineItem.find(line_item["id"])

              if l
                if line_item["quantity"].to_i > 0 and not line_item["quantity"].blank?
                  l.update_attributes(quantity: line_item["quantity"],
                                      comment: line_item["comment"],
                                      price: line_item["price"],
                                      returnable: line_item["returnable"], 
                                      ship_velocity: line_item["ship_velocity"])
                else
                  l.destroy
                end
              end
            else
              if line_item["variant_id"].present?
                Spree::PurchaseOrderLineItem.create(variant_id: line_item["variant_id"],
                                                    purchase_order_id: @purchase_order.id,
                                                    quantity: line_item["quantity"].to_i,
                                                    comment: line_item["comment"],
                                                    price: line_item["price"].to_f,
                                                    returnable: line_item["returnable"],
                                                    user_id: spree_current_user.id,
                                                    ship_velocity: line_item["ship_velocity"])
              end
            end
          end

          @purchase_order.purchase_order_line_items.each do |l|
            unless l.variant_id.present?
              l.destroy
            end
          end

          if @purchase_order.valid? 
            suggest_freight
            redirect_to edit_admin_purchase_order_path(@purchase_order.number)
          end

        end
      end

      def submit
        @purchase_order = find_resource

        # Check for delayed_job support or fork
        if Spree::PurchaseOrderMailer.respond_to?(:delay)
          resend = false
          @purchase_order.update_column(:submitting_admin_user_id, spree_current_user.id)
          @purchase_order.update_column(:admin_submitting_at, Time.new)
          if @purchase_order.submitted_at.present?
            resend = true
          end
          Spree::PurchaseOrderMailer.delay(run_at: 1.minutes.from_now).email_supplier(@purchase_order, resend)

        # else
        #   ::ActiveRecord::Base.clear_all_connections!
        #   fork do
        #     sleep 10
        #     Spree::PurchaseOrderMailer.email_supplier(@purchase_order, false).deliver
        #     exit
        #   end
        #   ::ActiveRecord::Base.establish_connection
        end

        respond_with(@purchase_order) do |format|
          format.html
          format.json { render(json: @purchase_order) }
          format.pdf { 
            render :pdf    => "#{@purchase_order.number}.pdf",
              :disposition => "inline",
              :page_size => "Letter",
              :layout      => "pdf",
              :template => "spree/admin/purchase_orders/show.pdf.erb",
              :save_to_file => Rails.root.join('tmp', 'pdfs', "#{@purchase_order.number}.pdf"),
              :show_as_html => params[:debug].present?            
          }
          format.rtf { send_data(@purchase_order.save_rtf, type: "application/rtf; charset=utf-8; header=present", disposition: "attachment; filename=#{@purchase_order.number}.rtf") }
        end
      end

      def complete
        @purchase_order = find_resource
        next_url = request.env["HTTP_REFERER"]

        if @purchase_order.dropship and @purchase_order.status == "Submitted"

          @purchase_order.status = "Completed"
          if @purchase_order.save
            if @purchase_order.orders 
              next_url = admin_order_payments_url(@purchase_order.orders.first)
            end
            flash[:success] = "#{@purchase_order.number} complete - You may capture payment on these orders now"
          else
            next_url = edit_admin_purchase_order_url(@purchase_order)
            flash[:error] = @purchase_order.errors.full_messages.join("; ")
          end
        else
          flash[:error] = "#{@purchase_order.number} is not a dropship or has not yet been submitted"
        end

        redirect_to next_url
      end

      def submitted
        @purchase_order = find_resource
        next_url = request.env["HTTP_REFERER"]

        if @purchase_order.status == "Entered"

          @purchase_order.status = "Submitted"
          if @purchase_order.save
            flash[:success] = "#{@purchase_order.number} marked as submitted"
          else
            next_url = edit_admin_purchase_order_url(@purchase_order)
            flash[:error] = @purchase_order.errors.full_messages.join("; ")
          end
        else
          flash[:error] = "#{@purchase_order.number} must have the status of Entered"
        end

        redirect_to next_url
      end      

      def destroy
        @purchase_order = Spree::PurchaseOrder.find_by_number(params[:id])
        next_url = admin_purchase_orders_url

        if @purchase_order
          flash[:success] = "#{@purchase_order.po_type} removed"

          @purchase_order.destroy
        else
          flash[:error] = "Could not load #{params[:id]}"
        end
        redirect_to next_url
      end

      protected

        def set_type
          @purchase_order = Spree::PurchaseOrder.new
          @purchase_order.dropship = (params[:type] == "DS" ? true : false)
          @purchase_order.user_id = spree_current_user.id
          @purchase_order.save validate: false
          @purchase_order.generate_number
          @purchase_order.purchase_order_line_items.build

          return @purchase_order
        end

        def find_resource
          param_id = params[:id] ? params[:id] : params[:purchase_order_id]
          po =  Spree::PurchaseOrder.find_by_number(param_id)
          @eligible_orders = Spree::Order.eligible_for_po(po)
          return po
        end

        def find_or_create_office_address
          @shipping_methods = ShippingMethod.where("display_on is null or display_on = '' or display_on = 'back_end'").order("zone_id asc, updated_at desc")

          country = Spree::Country.where('name = ? or iso = ? or iso3 = ? or iso_name = ?',
                                         Spree::Config.advanced_inventory_office_country,
                                         Spree::Config.advanced_inventory_office_country,
                                         Spree::Config.advanced_inventory_office_country,
                                         Spree::Config.advanced_inventory_office_country).first

          state = Spree::State.where('country_id = ? and (name = ? or abbr = ?)',
                                     country.id,
                                     Spree::Config.advanced_inventory_office_state.titleize,
                                     Spree::Config.advanced_inventory_office_state.upcase).first


          @office_address = Spree::Address.where(address1: Spree::Config.advanced_inventory_office_address1,
                                       address2: Spree::Config.advanced_inventory_office_address2,
                                       company: Spree::Config.advanced_inventory_office_company,
                                       city: Spree::Config.advanced_inventory_office_city,
                                       state_id: state.id,
                                       zipcode: Spree::Config.advanced_inventory_office_zip,
                                       country_id: country.id,
                                       phone: Spree::Config.advanced_inventory_office_phone,
                                       user_id: 1,
                                       firstname: "Shipping",
                                       lastname: "Receiving").first_or_create


        end

        def find_or_build_address
          if @purchase_order.dropship and params[:purchase_order][:address_id].to_i == 0
            @address = Spree::Address.where(firstname: params[:address][:firstname],
                                            lastname: params[:address][:lastname],
                                            company: params[:address][:company],
                                            phone: params[:address][:phone],
                                            alternative_phone: params[:address][:alternative_phone],
                                            address1: params[:address][:address1],
                                            address2: params[:address][:address2],
                                            city: params[:address][:city],
                                            zipcode: params[:address][:zipcode],
                                            country_id: params[:address][:country_id]).first





            if not @address
              @address = Spree::Address.new(params[:address])
              @address.save
            end

            params[:purchase_order][:address_id] = @address.id
          end
        end

        def remove_unused
          Spree::PurchaseOrder.where(status: nil, user_id: spree_current_user.id).each do |p|
            if p.purchase_order_line_items.size == 0
              p.destroy
            end
          end
        end

        def load_supplier
          supplier_contact = Spree::SupplierContact.find(params[:purchase_order][:supplier_contact_id])
          params[:purchase_order][:supplier_id] = supplier_contact.supplier_id
        end

        def update_orders
          eligible_orders = Spree::Order.eligible_for_po(@purchase_order)

          if params[:sending_manually] and params[:purchase_order][:status] == "Entered"
            params[:purchase_order][:status] = "Submitted"
          end

          if params[:order_ids] and params[:order_ids].size > 0
            @purchase_order.order_purchase_orders.destroy_all

            params[:order_ids].each do |oid|
              Spree::OrderPurchaseOrder.create(order_id: oid, purchase_order_id: @purchase_order.id)
            end

          elsif @purchase_order.status != "Completed" and not params[:order_ids] and eligible_orders.size > 0 
            @purchase_order.order_purchase_orders.destroy_all
          end
        end

        def suggest_freight
          if @purchase_order.requires_freight?
            if @purchase_order.status == "Entered" and not @purchase_order.freight_notice_displayed
              @freight = Spree::ShippingMethod.where("name = ?", "UPS Freight").first

              if @freight.present?
                @purchase_order.update_column(:shipping_method_id, @freight.id)
                @purchase_order.update_column(:freight_notice_displayed, true)

                flash[:notice] = "This PO is large enough to require a freight shipment"
              end
            end
          end
        end
    end
  end
end
