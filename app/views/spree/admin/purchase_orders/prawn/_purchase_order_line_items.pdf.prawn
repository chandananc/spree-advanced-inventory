bounding_box [0,370], :width => 540, :height => 300 do
  #move_down 2
  header =  ["SKU","Description", "Price", "Quantity", "Line total"]


  table [header],
    :position           => :center,
    :border_width => 1,
    :vertical_padding   => 2,
    :horizontal_padding => 6,
    :font_size => 12,
    :style => :bold,
    :column_widths => { 0 => 100, 1 => 225, 2 => 65, 3 => 75, 4 => 75 },
    :align => { 0 => :left, 1 => :left, 2 => :right, 3 => :right, 4 => :right }

  #move_down 4

  bounding_box [0,cursor], :width => 540 do
    #move_down 2
    content = []
    @purchase_order.purchase_order_line_items.each do |item|
      row = [ item.variant.sku, item.variant.product.name.split(":").first + " - " (item.returnable ? "Returnable" : "Non-returnable")]
      row << number_to_currency(item.price) unless @hide_prices
      row << item.quantity
      row << number_to_currency(item.price * item.quantity) unless @hide_prices
      content << row

      row = ["", (item.comment.blank? ? "" : item.comment) ]
      row << "" unless @hide_prices
      row << "" 
      row << "" unless @hide_prices
      content << row
    end


    table content,
      :position           => :center,
      :border_width => 0.5,
      :vertical_padding   => 5,
      :horizontal_padding => 6,
      :column_widths => { 0 => 100, 1 => 225, 2 => 65, 3 => 75, 4 => 75 },
      :font_size => 9, 
      :align => { 0 => :left, 1 => :left, 2 => :right, 3 => :right, 4 => :right }

  end

  font "Helvetica", :size => 9

  totals = []

  totals << [Prawn::Table::Cell.new( :text => "Sub-total", :font_style => :bold), number_to_currency(@purchase_order.gross_amount)]
  totals << [Prawn::Table::Cell.new( :text => "Shipping", :font_style => :bold), number_to_currency(@purchase_order.shipping.to_f)]
  totals << [Prawn::Table::Cell.new( :text => "Discount", :font_style => :bold), "(#{number_to_currency(@purchase_order.discount.to_f)})"]
  totals << [Prawn::Table::Cell.new( :text => "Deposit", :font_style => :bold), "(#{number_to_currency(@purchase_order.deposit.to_f)})"]

  totals << [Prawn::Table::Cell.new( :text => t(:total), :font_style => :bold), number_to_currency(@purchase_order.total)]

  bounding_box [bounds.right - 500, bounds.bottom + (totals.length * 18)], :width => 500 do
    table totals,
      :position => :right,
      :border_width => 0,
      :vertical_padding   => 2,
      :horizontal_padding => 6,
      :font_size => 9,
      :column_widths => { 0 => 425, 1 => 75 } ,
      :align => { 0 => :right, 1 => :right }

  end

  move_down 2

  stroke do
    line_width 0.5
    line bounds.top_left, bounds.top_right
    line bounds.top_left, bounds.bottom_left
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right
  end

end
