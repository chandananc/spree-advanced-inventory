module Spree
  module Admin
    module ManageStockHelper
      
      def url_for_queue(variant)
        if admin_product_inventory_path(variant.product) 
          admin_product_inventory_path(variant.product) + "##{variant.sku}"
        else
          admin_orders_path + "?q[variants_sku_cont]=#{variant.sku}&q[shipment_state_not_eq]=shipped"
        end
      end

      def url_for_reserved_order_search(variant)
        admin_orders_path + "?q[variants_sku_cont]=#{variant.sku}&q[shipment_state_not_eq]=shipped&q[payment_state_not_eq]=paid&q[is_dropship_eq]=false"
      end

      def url_for_queued_order_search(variant)
        admin_orders_path + "?q[variants_sku_cont]=#{variant.sku}&q[shipment_state_not_eq]=shipped&q[payment_state_eq]=paid&q[is_dropship_eq]=false"
      end

      def url_for_backordered_order_search(variant)
        admin_orders_path + "?q[variants_sku_cont]=#{variant.sku}&q[shipment_state_eq]=backorder&q[is_dropship_eq]=false"
      end

      def recent_price_history(variant)
        rp = variant.last_purchase_order_line_item

        if rp and rp.purchase_order
          price_history = "" 

          variant.purchase_order_line_items.where{(price > 0.0)}.order("updated_at desc").limit(10).each do |l|
            if l.purchase_order.present?
              price_history += l.updated_at.strftime("%m/%d/%Y") + " > #{l.purchase_order.number} > #{Spree::Money.new(l.price)}\n"
            end
          end

          price_history
        else
          "Variant cost price only"
        end
      end

    end
  end
end
