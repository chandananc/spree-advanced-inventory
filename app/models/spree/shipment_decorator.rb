Spree::Shipment.class_eval do

  has_many :stock_units, :through => :inventory_units

  before_validation :ship_stock_units

  def ship_stock_units
    if state == "shipped"
      stock_units.update_all(state: "shipped")
    end

    true
  end

  def send_shipped_email
    unless order.is_quote
      if Spree::ShipmentMailer.respond_to?(:delay)
        Spree::ShipmentMailer.delay.shipped_email(self.id)
      else
        Spree::ShipmentMailer.shipped_email(self.id).deliver
      end
    end
  end  
end
