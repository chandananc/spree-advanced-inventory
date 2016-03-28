class Spree::StockUnit < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :variant
  belongs_to :inventory_unit
  belongs_to :purchase_order_line_item

  attr_accessible :variant_id, :inventory_unit_id, :purchase_order_line_item_id, :cost, :state, :last_state_change_at

  scope :available, where(state: "available")

  before_save :update_last_state_change_at

  def update_last_state_change_at
    if state_changed?
      self.last_state_change_at = Time.new
    end

    true
  end

  def shipment
    inventory_unit.shipment
  end

  def self.receive(purchase_order_line_item, received_purchase_order_line_item)
    stock_units = Array.new

    1.upto(received_purchase_order_line_item.quantity).each do |n|
      su = create(variant_id: purchase_order_line_item.variant_id,
             purchase_order_line_item_id: purchase_order_line_item.id,
             cost: purchase_order_line_item.price,
             last_state_change_at: Time.new)
      stock_units.push(su)
    end

    return stock_units
  end

  def self.next_available_unit
    Spree::StockUnit.next_available_units(1).first
  end

  def self.next_available_units(num = 1)
    where(state: "available").order("created_at asc").limit(num)
  end

  def self.reserve_by_line_item(l,i)
    u = Spree::StockUnit.next_available_units(1).where(purchase_order_line_item_id: l.id).first
    if u.present?
      u.reserve(i)
    end
  end

  def self.reserve_units(order, variant, quantity)
    if order.use_stock

      order.inventory_units.
        where("state != ? and variant_id = ?", "backordered", variant.id).
        order("created_at asc").
        limit(quantity).
        each do |i|
          unless i.stock_unit
            stock_unit = Spree::StockUnit.next_available_unit
            if stock_unit.present?
              stock_unit.reserve(i)
            end
          end

      end
    end
  end

  def self.release_units(order, variant, quantity)
    if order.use_stock

      order.inventory_units.
        where("state != ? and variant_id = ?", "backordered", variant.id).
        order("created_at asc").
        limit(quantity).
        each do |i|

          if i.stock_unit.present?
            i.stock_unit.release
          end

      end
    end
  end

  def self.reassign(old_unit, new_unit)
    if stock_unit = old_unit.stock_unit
      stock_unit.release
      stock_unit.reserve(new_unit)
    end
  end

  def reserve(i)
    self.state = "reserved"
    self.inventory_unit_id = i.id
    self.save
  end

  def ship
    self.state = "shipped"
    self.save
  end

  def release
    self.state = "available"
    self.inventory_unit_id = nil
    self.save
  end

  def order_line_item
    if state != "available"
      inventory_unit.order.line_item.where(variant_id: variant_id).first
    else
      nil
    end
  end

  def order
    if state != "available"
      inventory_unit.order
    else
      nil
    end
  end

end
