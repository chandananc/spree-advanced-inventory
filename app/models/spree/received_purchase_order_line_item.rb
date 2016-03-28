class Spree::ReceivedPurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order_line_item
  attr_accessible :quantity, :received_at, :purchase_order_line_item_id

  def purchase_order
    purchase_order_line_item.purchase_order
  end

end
