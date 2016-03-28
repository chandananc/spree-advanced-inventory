class Spree::PurchaseOrderLineItem < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :variant
  belongs_to :line_item
  belongs_to :user
  has_one :supplier, through: :purchase_order

  has_many :received_purchase_order_line_items
  has_many :stock_units

  attr_accessible :price, :quantity, :purchase_order_id, :variant_id,
    :user_id, :comment, :returnable, :ship_velocity

  validates :variant_id, presence: true
  validates :quantity, :price, numericality: true

  def product
    variant.product
  end

  def status
    (received_purchase_order_line_items.sum(:quantity).to_i == quantity.to_i) ? "Complete" : "Incomplete"
  end

  def receive(qty_recv)
    r = received_purchase_order_line_items.create(quantity: qty_recv.to_i, received_at: Time.now)
    Spree::StockUnit.receive(self, r)

    return r
  end

  def received
    if received_purchase_order_line_items.size > 0
      received_purchase_order_line_items.pluck(:quantity).sum
    else
      0
    end
  end

  def line_total
    quantity * price
  end

  def gross_profit_percentage
    total_revenue = 0.0

    if purchase_order.orders.size > 0
      purchase_order.orders.each do |o|
        total_revenue += o.line_items.where(variant_id: variant_id).sum("quantity * price").to_f
      end

      sprintf("%0.2f%", ((total_revenue - line_total) / total_revenue) * 100)
    else
      ""
    end
  end

end
