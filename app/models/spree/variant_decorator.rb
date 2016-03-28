Spree::Variant.class_eval do
  # Stock types:
  # R => Regular
  # C => Consignment
  # B => Buyback

  attr_accessible :stock_type, :section, :subsection, :pallet, :last_scanned_at
  attr_accessor :best_unit_price

  before_validation :ensure_sku_stock_type

  has_many :purchase_order_line_items
  has_many :purchase_orders, through: :purchase_order_line_items
  has_many :orders, through: :line_items
  has_many :suppliers, through: :purchase_orders, uniq: true
  has_many :stock_units

  def short_name
    product.name.split(":").first
  end

  def available_stock_units(start_at, end_at)
    stock_units.where("state = ? and last_state_change_at >= ? and last_state_change_at <= ?", "available", start_at, end_at)
  end

  def self.regular_stock
    where(stock_type: "R")
  end

  def stock_type_label
    if stock_type == "R"
      ""
    elsif stock_type == "C"
      "Consignment"
    elsif stock_type == "B"
      "Buyback"
    end
  end

  def ensure_sku_stock_type
    success_state = true
    self.stock_type = stock_type[0].upcase

    if sku =~ /^978/ 
      # Size starts at 1
      # Arrays start at 0 
      # Last character is size - 1.
      prev = sku[sku.size - 1]

      if prev != stock_type 
        if ["C","B"].include?(prev)
          self.sku = sku[0..(sku.size - 2)]
        end

        unless stock_type == "R"
          self.sku += stock_type
        end
      end
    end

    if exists = Spree::Variant.where("deleted_at is null and is_master = false and sku = ? and id != ?", sku, id).first
      errors.add(:sku, "is already in use by: #{exists.product.name.split(":").first}")
      success_state = false
    end

    return success_state
  end

  def receive(qty)
    if on_hand > 0
      qty += count_on_hand
    end

    self.count_on_hand = qty
    self.save
  end

  # This routine was always being called before saving variants and causing havok with 
  # stock levels
  def on_demand=(on_demand)
    #self[:on_demand] = on_demand
    #if on_demand
    #  inventory_units.with_state('backordered').each(&:fill_backorder)
    #end
  end

  def last_n_purchase_order_line_items(n = 1)
    purchase_order_line_items.where{(price != nil) & (price > 0.0)}.order("updated_at desc").limit(n)
  end

  def last_purchase_order_line_item
    l = last_n_purchase_order_line_items(1)

    return l.first
  end

  def weighted_average_cost
    unless @best_unit_price 
      p = 0.0
      rp = last_n_purchase_order_line_items(30)
      rp_count = rp.size

      if rp_count > 0
        if rp_count > 1
          p = purchase_order_line_items.where{(price != nil) & (price > 0.0)}.select("sum(price * quantity) / sum(quantity) as wavco").first.wavco.to_f
        else
          line_item = rp.first

          if line_item and line_item.price
            p = line_item.price.to_f
          end
        end

      elsif cost_price != nil and cost_price.to_f > 0.0
        p = cost_price.to_f

      end

      @best_unit_price = sprintf("%0.2f", p).to_f
    end

    return @best_unit_price
  end

  def ebook?
    if sku =~ /-ebook/i
      true
    else
      false
    end
  end
  
  # Will deprecate this inaccurately named method
  def recent_price
    if not ebook?
      weighted_average_cost
    else
      0.0
    end
  end

  private

    def process_backorders
      if count_changes = changes['count_on_hand']
        new_level = count_changes.last

        if Spree::Config[:track_inventory_levels] && !self.on_demand
          new_level = new_level.to_i
          order_list = Array.new

          # update backorders if level is positive
          if new_level > 0

            units_reserved = 0

            # fill backordered orders before creating new units
            backordered_units = inventory_units.order("created_at asc").with_state('backordered')
            
            backordered_units.each do |i|
               
              if new_level > 0 and i.order.state != "canceled"
                unless order_list.include?(i.order_id)
                  order_list.push(i.order_id)
                end
                i.fill_backorder

                unless i.stock_unit
                  su = Spree::StockUnit.next_available_unit
                  su.reserve(i)
                end
                units_reserved += 1
                new_level -= 1
              end
            end


            if respond_to?(:reason)
              self.reason = "Reserving #{units_reserved} for existing backorders"
              log_changes
            end
          end

          Spree::Order.transaction do
            if order_list.size > 0
              order_list.each do |oid|
                o = Spree::Order.find(oid)
                o.shipments.each do |shipment|

                  unless shipment.state == "shipped"
                    shipment.update!(o)
                  end
                end

                o.updater.update_shipment_state
                o.update_attributes_without_callbacks({ :shipment_state => o.shipment_state })
              end
            end

            if new_level == 0
              bo_units = inventory_units.order("created_at asc").with_state('backordered').size
              if bo_units > 0
                new_level = 0 - bo_units
              end
            end
            self.update_attribute_without_callbacks(:count_on_hand, new_level)

            if respond_to?(:reason)
              self.reason = "count_on_hand set to #{new_level}"
              log_changes
            end
          end
        end
      end
    end    

end

