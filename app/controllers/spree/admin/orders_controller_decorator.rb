Spree::Admin::OrdersController.class_eval do
  def new
    @order = Spree::Order.create

    if params[:is_quote]
      @order.update_column(:is_quote, true)
      @order.update_column(:inventory_adjusted, false)

    elsif params[:is_dropship]
      @order.update_column(:is_dropship, true)
      @order.update_column(:inventory_adjusted, false)

    else
      @order.update_column(:is_dropship, false)
      @order.update_column(:is_quote, false)
      @order.update_column(:inventory_adjusted, true)

    end

    respond_with(@order)
  end  
end
