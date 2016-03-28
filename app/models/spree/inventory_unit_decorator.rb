Spree::InventoryUnit.class_eval do
  attr_accessible :is_dropship, :is_quote
  has_one :stock_unit
  before_validation :set_stock_type

  def self.queued
    joins(:order).where("spree_orders.payment_state = ? and spree_inventory_units.is_dropship = false and spree_inventory_units.is_quote = false and spree_inventory_units.state = ?", "paid", "sold")
  end

  def self.reserved
    joins(:order).where("(spree_orders.payment_state = ? or spree_orders.payment_state = ?)  and spree_inventory_units.is_dropship = false and spree_inventory_units.is_quote = false and spree_inventory_units.state = ?", "balance_due", "failed", "sold")
  end

  def set_stock_type
    if order.is_dropship == true
      self.is_dropship = true

      if shipment
        if shipment.state != "shipped"
          self.state = "sold"
        elsif shipment.state == "shipped" and return_authorization_id == nil
          self.state = "shipped"
        end
      end
    else
      self.is_dropship = false
    end 

    if order.is_quote == true
      self.is_quote = true
    else
      self.is_quote = false
    end 

    return true
  end

  def self.increase(order, variant, quantity)
    back_order = determine_backorder(order, variant, quantity)
    sold = quantity - back_order

    #set on_hand if configured
    if self.track_levels?(variant) and order.use_stock
      if variant.respond_to?(:reason)
        variant.reason = "Allocating #{quantity} units to #{order.number} as #{sold} sold / #{back_order} backordered"
      end

      variant.decrement!(:count_on_hand, quantity)

    end

    #create units if configured
    if Spree::Config[:create_inventory_units]
      Spree::InventoryUnit.transaction do
        create_units(order, variant, sold, back_order)

        Spree::StockUnit.reserve_units(order, variant, sold)
      end
    end
  end 

  def self.decrease(order, variant, quantity)

    # Do not recreate stock levels for dropships
    if self.track_levels?(variant) and order.use_stock
      if variant.respond_to?(:reason)
        variant.reason = "Order #{order.number} no longer wants #{quantity} units"
      end

      variant.increment!(:count_on_hand, quantity)
      
    end

    if Spree::Config[:create_inventory_units]
      Spree::InventoryUnit.transaction do
        Spree::StockUnit.release_units(order, variant, quantity)
        destroy_units(order, variant, quantity)
      end
    end
  end
 
  def restock_variant
    if self.class.track_levels?(variant) and order.use_stock
      variant.on_hand += 1
      variant.save

      if stock_unit
        stock_unit.release
      end
    end
  end


  def backordered?
    state == "backordered" ? true : false
  end

  private
    def update_order
      #order.update!
    end  

    def self.determine_backorder(o, v, q)

      if not o.use_stock
        0
      else
        if v.on_hand == 0 
          q
        elsif v.on_hand.present? and v.on_hand < q 
          q - (v.on_hand < 0 ? 0 : v.on_hand)
        else
          0
        end
      end
    end
end
