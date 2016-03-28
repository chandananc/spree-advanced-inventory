module Spree
  module Admin
    class PurchaseOrderLineItemsController < ResourceController
      respond_to :js

      def create
        @purchase_order_line_item =
          Spree::PurchaseOrderLineItem.where(
            user_id: spree_current_user.id,
            purchase_order_id: params[:purchase_order_id],
            variant_id: params[:add_variant_id],
            price: params[:add_price].to_f,
            quantity: params[:add_quantity].to_i).first_or_create

      end
    end
  end
end
