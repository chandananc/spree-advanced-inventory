Spree::Admin::PaymentsController.class_eval do 
  append_before_filter :handle_quotes

  def handle_quotes
    if @payment_methods and @order and @order.is_quote
      @payment_methods = Spree::PaymentMethod.where(name: "Quote")
    elsif @payment_methods and @order and not @order.is_quote
      @payment_methods = Spree::PaymentMethod.where{(name != "Quote")}.available(:back_end)
    end
  end
end
