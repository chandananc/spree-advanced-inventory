Spree::LineItem.class_eval do
  has_many :suppliers, through: :variants

  def sufficient_stock?
    return true if Spree::Config[:allow_backorders] or not order.use_stock
    if new_record? || !order.completed?
      variant.on_hand >= quantity
    else
      variant.on_hand >= (quantity - self.changed_attributes['quantity'].to_i)
    end
  end  
end
