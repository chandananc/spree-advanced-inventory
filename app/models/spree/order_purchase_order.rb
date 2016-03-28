class Spree::OrderPurchaseOrder < ActiveRecord::Base
  attr_accessible :purchase_order_id, :order_id

  belongs_to :order
  belongs_to :purchase_order

  def self.import_from_orders
    Spree::Order.where("purchase_order_id is not null").each do |o|
      Spree::OrderPurchaseOrder.where(order_id: o.id, 
                                      purchase_order_id: o.purchase_order_id).first_or_create
    end
  end
end

