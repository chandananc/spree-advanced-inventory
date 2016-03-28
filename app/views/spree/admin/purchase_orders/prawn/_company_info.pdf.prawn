bounding_box [0,680], :width => 200 do

  data = [[text("REMIT TO", style: :bold)]]
  data << [Prawn::Table::Cell.new(text: Spree::Config.advanced_inventory_office_company)]
  data << [Prawn::Table::Cell.new(text: Spree::Config.advanced_inventory_office_address1)]
  data << [Spree::Config.advanced_inventory_office_address2]
  data << ["#{Spree::Config.advanced_inventory_office_city}, #{Spree::Config.advanced_inventory_office_state} #{Spree::Config.advanced_inventory_office_zip}"]
  data << [Spree::Config.advanced_inventory_office_country]

  table data,
    :position => :center,
    :border_width => 0.5,
    :vertical_padding   => 0,
    :horizontal_padding => 0,
    :font_size => 10,
    :border_style => :underline_header,
    :column_widths => { 0 => 200 }

end

bounding_box [370,660], :width => 170 do
  move_down 1

  data = [[" "]]
  data << ["Phone: #{Spree::Config.advanced_inventory_office_phone}"]
  data << ["E-mail: #{Spree::Config.advanced_inventory_office_email}"]
  data << ["Federal Tax ID: #{Spree::Config.advanced_inventory_tax_id}"]


  table(data,
    :align => { 0 => :right },
    :position => :center,
    :border_width => 0.5,
    :vertical_padding   => 0,
    :horizontal_padding => 0,
    :font_size => 10,
    :border_style => :underline_header,
    :column_widths => { 0 => 170 })
end

move_down 30
