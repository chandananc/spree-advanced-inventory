bounding_box [180,560], :width => 170, :height => 150 do
  move_down 1

  text "Account / Rep", align: :left, style: :bold, size: 18
  move_down 4

  data = [["Number: #{supplier.account_number}"]]

  if supplier.nr_account_number  
    data << ["NR account: #{supplier.nr_account_number}"]
  end

  data << ["Contact: #{contact.name}"]
  
  if contact.phone
    data << ["Phone: #{contact.phone}"]
  end

  if contact.email
    data << ["E-mail: #{contact.email}"]
  end

  table data,
    :position => :center,
    :border_width => 0.5,
    :vertical_padding   => 1,
    :horizontal_padding => 0,
    :font_size => 10,
    :border_style => :underline_header,
    :column_widths => { 0 => 170 }

  stroke do
    line_width 0.5
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right
  end
end


