bounding_box [370,560], :width => 170, :height => 150 do
  move_down 1

  text "Ship To", align: :left, style: :bold, size: 18
  move_down 4

  render partial: "spree/admin/purchase_orders/prawn/address", locals: { address: address }

  move_down 4

  text "Method: #{@purchase_order.shipping_method.name}", align: :left, style: :bold, size: 10
 

  stroke do
    line_width 0.5
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right

  end

end


