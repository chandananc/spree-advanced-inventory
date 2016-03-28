Spree::Order.class_eval do
  has_many :order_purchase_orders
  has_many :purchase_orders, through: :order_purchase_orders
  has_many :purchase_order_line_items, through: :purchase_orders
  has_many :received_purchase_order_line_items, through: :purchase_order_line_items
  has_many :suppliers, through: :purchase_orders
  attr_accessible :is_dropship, :inventory_adjusted, :is_quote, :restock_return

  before_save :dropship_conversion
  before_save :ensure_stock_unit
  before_validation :empty_nil_slug
  validate :check_is_dropship
  
  HUMANIZED_ATTRIBUTES = {
    :is_dropship => "Dropship"
  }

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def ensure_stock_unit
    #inventory_units.where("stock_unit_id is null and state != ?", "backordered").each do |i|
    #  i.stock_unit = Spree::StockUnit
    #end

    true
  end

  def check_is_dropship
    if is_dropship and has_normal_purchase_orders
      errors.add(:is_dropship, "cannot be Yes while this order is associated with regular POs")
    end 
  end

  def has_normal_purchase_orders
    ebook_po = purchase_order_for_ebooks.first

    if ebook_po
      purchase_orders.where("spree_purchase_orders.dropship = ? and spree_purchase_orders.id != ?", false, ebook_po.id).size > 0 ? true : false
    else
       purchase_orders.where("spree_purchase_orders.dropship = ?", false).size > 0 ? true : false
    end
  end

  def to_select
    value = "#{number} - From: #{email} - $#{total}"

    return value
  end

  def purchase_order
    purchase_orders
  end

  def use_stock
    if is_dropship or is_quote
      if state =~ /return/i and is_dropship and restock_return
        true
      else
        false
      end
    else
      true
    end
  end

  def empty_nil_slug
    if slug == nil
      self.slug = ""
    end
    return true
  end

  def dropship_conversion
    unless completed_at == nil
      if is_dropship 
        make_dropship

      elsif not is_dropship and is_dropship_was == true
        make_regular

      end 
    end

    return true
  end

  def make_dropship
    toggle_ia = false

    line_items.joins(:variant).each do |l|

      if inventory_adjusted == true
        adjust_variant_stock(l.variant, l.quantity)
        toggle_ia = true
      end

      variant_inventory_units(l.variant_id).each do |i|
        update_inventory_unit(i, "sold")
      end
    end

    if toggle_ia
      self.inventory_adjusted = false
    end
  end

  def make_regular
    toggle_ia = false

    line_items.joins(:variant).where("spree_variants.ebook != true").each do |l|
      current_on_hand = l.variant.on_hand

      if not inventory_adjusted
        adjust_variant_stock(l.variant, l.quantity * -1)
        toggle_ia = true
      end

      if current_on_hand >= l.quantity
        variant_inventory_units(l.variant_id).each do |i|
          update_inventory_unit(i, "sold")
        end

      else
        counter = 1

        variant_inventory_units(l.variant_id).each do |i|
          if counter <= current_on_hand
            update_inventory_unit(i, "sold")
          else
            update_inventory_unit(i, "backordered")
          end

          counter += 1
        end
      end
    end
    
    if toggle_ia 
      self.inventory_adjusted = true
    end
  end

  def pending_credit_card_payment_total
    cc_total = 0.0
    pending_payments.each do |p|
      if p.source_type == "Spree::CreditCard"
        cc_total += p.amount
      end
    end

    return cc_total
  end

  def pending_check_payment_total
    check_total = 0.0
    pending_payments.each do |p|
      if p.source_type == nil
        check_total += p.amount
      end
    end

    return check_total
  end

  def pending_payments
    pending = Array.new
    payments.each do |p|
      if (p.state == "pending" or p.state == "checkout")
        pending.push(p)
      end
    end

    return pending
  end

  def try_to_capture_payment
    cc_total = pending_credit_card_payment_total
    non_cc_total = pending_check_payment_total

    # Our app allows payment capturing to be turned off so we check if that support
    # exists first and if it does we test if payments could be captured
    if not respond_to?(:can_capture_payments?) or can_capture_payments?
      if (not only_ebooks? and (cc_total.to_f + non_cc_total.to_f + ebook_order_total.to_f) == total.to_f) or (cc_total.to_f + non_cc_total.to_f == total.to_f)
        pending_payments.each do |p|
          begin
            p.capture!
            p.save
          rescue Spree::Core::GatewayError => ge
            update_staff_comments(ge.message)
          end
        end
      else
        unless payment_state == "paid"
          update_staff_comments("Payment totals did not match order total")
          self.save
        end
      end
    else
      # Payment captures can be disabled and are currently not possible so store
      # the reason why in the staff comments
      update_staff_comments("Could not auto capture payment #{no_payment_capture_reason}")
      self.save
    end
  end

  def update_staff_comments(comment)
    if respond_to?(:staff_comments)
      unless staff_comments =~ /#{Time.current.strftime("%m/%d")}/
        t = Time.current.strftime("%m/%d %l:%M %P")
        comment = "* Autopay problem: #{comment} on #{t}"
        update_attributes_without_callbacks({ :staff_comments => "#{staff_comments}\n#{comment}\n" })
      end
    end
  end

  def try_to_update_shipment_state
    shipments.each do |shipment|
      shipment.update!(self)
      shipment.save
    end

    updater.update_shipment_state
    update_attributes_without_callbacks({ :shipment_state => shipment_state })
  end

  def try_to_ship_shipments
    if can_ship?
      shipments.each do |shipment|
        shipment.update!(self)
        shipment.ship!
        shipment.save
      end
      updater.update_shipment_state
      update_attributes_without_callbacks({ :shipment_state => shipment_state })
    end
  end

  def variant_inventory_units(variant_id)
    inventory_units.where(variant_id: variant_id)
  end

  def adjust_variant_stock(variant, quantity)
    if quantity >= 0
      variant.increment!(:count_on_hand, quantity)
    else
      variant.decrement!(:count_on_hand, quantity.abs)
    end
  end

  def update_inventory_unit(i, new_state)
    i.state = new_state
    i.is_dropship = is_dropship
    i.save validate: false
  end

  def self.eligible_for_po(po)
    dropship_check = ""

    if po and po.dropship
      dropship_check = "o.is_dropship = true and"
    end
  
    find_by_sql(["select distinct o.* 
                from spree_orders o, spree_line_items l 
                where o.completed_at is not null and #{dropship_check} 
                (o.state = 'complete' or o.state = 'resumed') and
                o.shipment_state != 'shipped' and  
                l.order_id = o.id and 
                o.is_quote != true and
                l.variant_id in (select distinct(variant_id) from spree_purchase_order_line_items where purchase_order_id = ?) 
                order by 
                o.completed_at desc limit 100", po.id])
  end

  def after_cancel
    unless is_quote
      restock_items!

      if Spree::OrderMailer.respond_to?(:delay)
        Spree::OrderMailer.delay.cancel_email(self.id)
      else
        Spree::OrderMailer.cancel_email(self.id).deliver
      end

      unless %w(partial shipped).include?(shipment_state)
        self.payment_state = 'credit_owed'
      end
    end
  end  
end
