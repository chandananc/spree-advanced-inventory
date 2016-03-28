module Spree
  module Admin
    class ManageStockController < BaseController
      require 'barby'
      require 'barby/barcode/bookland'
      require 'barby/outputter/html_outputter'
      require 'lisbn'

      before_filter :load_variant_from_sku, only: [:update_by_sku, :update_sku]

      def index

      end

      def load_variant_from_sku
        @select_disabled = false
        @select_enabled = true

        if not params[:disable_payment_captures]
          params[:disable_payment_captures] = Spree::Config.advanced_inventory_disable_payment_captures
        end
        
        if params[:disable_payment_captures] == "true"
          Spree::Config.advanced_inventory_disable_payment_captures = "true"
          @select_disabled = true
          @select_enabled = false
        end

        @inventory = nil
        @variant = nil
        @product = nil
        @total_reserved = 0
        @total_on_hand = 0
        @total_queued = 0

        if params[:variant_id]
          @variant = Spree::Variant.find(params[:variant_id])

        elsif params[:sku] and params[:sku].size > 0
          s = params[:sku] 
          @variant = Spree::Variant.where{(sku == s) & (deleted_at == nil) & (is_master == false)}.first
          
          unless @variant
            no_text_sku = params[:sku].gsub(/\D/,"")

            if no_text_sku.size == 10 
              i = Lisbn.new(no_text_sku)

              if i.valid?
                params[:sku] = i.isbn13
              end
            elsif no_text_sku.size != 13
              ean_sku = ean_barcode_to_isbn13(no_text_sku)

              if ean_sku
                params[:sku] = ean_sku
              end
            elsif no_text_sku.size == 13
              params[:sku] = no_text_sku
            end
            
            s = params[:sku] 
            @variant = Spree::Variant.where{(sku == s) & (deleted_at == nil) & (is_master == false)}.first
          end
        end
        
        if @variant
          if not @variant.cost_price
            @variant.cost_price = @variant.recent_price || 0.0
          end

          @product = @variant.product
          @total_reserved = @variant.inventory_units.reserved.size
          @total_queued = @variant.inventory_units.queued.size
          @total_on_hand =  @total_reserved + (@variant.count_on_hand > 0 ? @variant.count_on_hand : 0)
          @backordered = 0

          if @variant.count_on_hand < 0
            @backordered = @variant.count_on_hand.abs
          end
          
          @variant.update_column(:last_scanned_at, Time.new)
        end

      end

      def update_sku
        if params[:section]
          @variant.section = params[:section]
        end

        if params[:subsection]
          @variant.subsection = params[:subsection]
        end

        if params[:pallet]
          @variant.pallet = params[:pallet]
        end        

        if params[:cost_price]
          @variant.cost_price = params[:cost_price]
        end
        
        if params[:total_on_hand]
          updated_count = params[:total_on_hand].to_i - @total_reserved

          if updated_count >= 0 and @variant.count_on_hand >= 0
            @variant.count_on_hand = updated_count
          elsif updated_count < 0
            flash[:error] = "TOTAL STOCK minus RESERVED STOCK must not be a negative number"
          elsif @variant.count_on_hand < 0 
            flash[:error] = "Cannot update backordered variants (hint: receive inventory normally)"
          end
        end

        @total_on_hand =  @total_reserved + (@variant.count_on_hand > 0 ? @variant.count_on_hand : 0)

        if @variant.changed? and params[:commit] == "Save"
          if @variant.save
            flash[:success] = "#{@product.name.split(":").first} #{@variant.options_text.split(":").last} updated"
          else
            flash[:error] = @variant.errors.full_messages.join("<br/>")
          end
        end

        redirect_to admin_update_by_sku_path + "?sku=#{@variant.sku}"
      end

      def update_by_sku

        if params[:disable_payment_captures] and params[:disable_payment_captures] == "false"
          Spree::Config.advanced_inventory_disable_payment_captures = "false"
        end

        render layout: false
      end

      def ean_barcode_to_isbn13(s)
        s.gsub!(/^011978/, "")
        s.gsub!(/^01978/, "")

        s = s[0..(s.size - 2)]

        if s.size == 9
          isbn10 = ""
          check = 0
          counter = 1

          s.scan(/\w/).each do |d|
            isbn10 += "#{d}"
            check += d.to_i * counter
            counter += 1
          end

          check = check % 11

          if check == 10
            check = "X"
          end

          isbn10 += "#{check}"
          s = Lisbn.new(isbn10)
          if s.valid?
            s.isbn13
          else
            nil
          end
        else
          nil
        end
      end

      def last_scanned_at
        @last_scanned_at = Time.new
        @variants = nil

        if params[:last_scan_date]
          last_scanned = @last_scanned_at = Time.parse(params[:last_scan_date].gsub(/\//, "-") + " 00:00:00")
          @variants = Spree::Variant.where{(last_scanned_at != nil) & 
                                           (last_scanned_at < last_scanned)}
        else
          @variants = Spree::Variant.where{(last_scanned_at == nil) & ((count_on_hand > 0) | (count_on_hand < 0))}
        end

        @variants = @variants.where{(is_master == false) &
                                    (deleted_at == nil)}.
        joins(:product).
        select("spree_variants.*, spree_products.name, spree_products.permalink").
        order("spree_products.name asc")
      end

      def full_inventory_report
        @inventory = Spree::FullInventory.where{ (count_on_hand != 0) | (reserved_units != 0)}.order("title asc, sku asc")

        if params[:sku] and params[:sku].size > 0
          @inventory = @inventory.where(sku: params[:sku].strip)
        else
          if params[:first_letter]
            l = params[:first_letter].to_s
            @inventory = @inventory.where{(title =~ "#{l}%")}
          end

        end

        if not params[:disable_payment_captures]
          params[:disable_payment_captures] = Spree::Config.advanced_inventory_disable_payment_captures
        end

        if params[:disable_payment_captures] == "true"
          Spree::Config.advanced_inventory_disable_payment_captures = "true"
        else
          params.delete(:disable_payment_captures)
          Spree::Config.advanced_inventory_disable_payment_captures = "false"
        end

        if params[:hide_backorders] and params[:hide_backorders] != "true"
          params.delete(:hide_backorders)
        end
        render layout: false
      end

      def receive_entire_po
        @po = Spree::PurchaseOrder.find_by_number(params[:purchase_order_id])

        if request.post?
          @po.purchase_order_line_items.each do |p|
            if params["section-#{p.id}"].present?
              p.variant.update_column(:section, params["section-#{p.id}"])
            end
            if params["subsection-#{p.id}"].present?
              p.variant.update_column(:subsection, params["subsection-#{p.id}"])
            end
            if params["pallet-#{p.id}"].present?
              p.variant.update_column(:pallet, params["pallet-#{p.id}"])
            end
          end
          @po.receive_entire_po(spree_current_user)

          flash[:success] = "PO #{@po.number} fully received"
          redirect_to admin_purchase_orders_path
        end
      end

      def update
        @variant = Spree::Variant.find(params[:variant_id])

        @po_line_items =
          @variant.purchase_order_line_items.
          joins(:purchase_order).
          where('spree_purchase_orders.dropship' => false).
          order("created_at desc").
          limit(50)


        @ds_line_items =
          @variant.purchase_order_line_items.
          joins(:purchase_order).
          where('spree_purchase_orders.dropship' => true).
          order("created_at desc").
          limit(20)

        if request.post?
          quantity = params[:receive].to_i
          if quantity > 0            
            if params[:receive_type] == "po"
              @line_item = Spree::PurchaseOrderLineItem.find(params[:received_id])

              if @line_item

                if @line_item.variant.respond_to?(:admin_log_user_id)
                  @line_item.variant.update_column(:admin_log_user_id, spree_current_user.id)
                end

                if params["section-#{@line_item.id}"].present?
                  @line_item.variant.update_column(:section, params["section-#{@line_item.id}"])
                end
                if params["subsection-#{@line_item.id}"].present?
                  @line_item.variant.update_column(:subsection, params["subsection-#{@line_item.id}"])
                end
                if params["pallet-#{@line_item.id}"].present?
                  @line_item.variant.update_column(:pallet, params["pallet-#{@line_item.id}"])
                end                

                @line_item.receive(quantity)
                @line_item.purchase_order.items_received(@line_item.id => quantity)
                @po = @line_item.purchase_order

                unless @po.fully_received?
                  Spree::PurchaseOrderMailer.delay.partially_received_notice(@po)
                end

                flash[:success] = flash_message_for(@variant, "received stock")
                redirect_to action: :update, variant_id: @variant.id

              else
                flash[:error] = flash_message_for(@variant, "Could not find that purchase order line item")
                redirect_to action: :update, variant_id: @variant.id, method: "get"
              end
            end
          end
        end
      end
    end
  end
end


