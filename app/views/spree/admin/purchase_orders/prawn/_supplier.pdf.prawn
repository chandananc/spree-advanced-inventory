bounding_box [0,560], :width => 170, :height => 150 do
  move_down 1

  text "Supplier", align: :left, style: :bold, size: 18
  move_down 4

  render partial: "spree/admin/purchase_orders/prawn/address", locals: { address: address }

  stroke do
    line_width 0.5
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right

  end
end


