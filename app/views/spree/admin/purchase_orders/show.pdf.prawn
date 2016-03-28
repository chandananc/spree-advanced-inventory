require 'prawn/layout'

font "Helvetica"
im = "#{Rails.root.to_s}/public/assets/#{Spree::PrintInvoice::Config[:print_invoice_logo_path]}"

image im , at: [0,720] #, scale: 0.35

fill_color "D8D8D8"

if @purchase_order.dropship
  text "Dropship", align: :right, style: :bold, size: 18
else
  text "Purchase Order", align: :right, style: :bold, size: 18
end

fill_color "000000"

move_down 2

font "Helvetica",  size: 9,  style: :bold
text "##{@purchase_order.number}", align: :right

if @purchase_order.orders and @purchase_order.orders.size > 0
  move_down 2
  font "Helvetica", size: 8
  text "Reference #: #{@purchase_order.orders.collect(&:number).join(", ")}", align: :right
end

font "Helvetica",  size: 9

bounding_box [0,660], :width => 200 do
  move_down 1

  data = [[Prawn::Table::Cell.new(text: Spree::Config.advanced_inventory_office_address1)]]
  data << [Spree::Config.advanced_inventory_office_address2]
  data << ["#{Spree::Config.advanced_inventory_office_city}, #{Spree::Config.advanced_inventory_office_state} #{Spree::Config.advanced_inventory_office_zip}"]
  data << [Spree::Config.advanced_inventory_office_country]

  table data,
    :position => :center,
    :border_width => 0.5,
    :vertical_padding   => 0,
    :horizontal_padding => 0,
    :font_size => 8,
    :border_style => :underline_header,
    :column_widths => { 0 => 200 }

end

bounding_box [370,660], :width => 170 do
  move_down 1

  data = [["Phone: #{Spree::Config.advanced_inventory_office_phone}"]]
  data << ["E-mail: #{Spree::Config.advanced_inventory_office_email}"]
  data << ["Federal Tax ID: #{Spree::Config.advanced_inventory_tax_id}"]
  data << [""]


  table(data,
    :align => { 0 => :right },
    :position => :center,
    :border_width => 0.5,
    :vertical_padding   => 0,
    :horizontal_padding => 0,
    :font_size => 8,
    :border_style => :underline_header,
    :column_widths => { 0 => 170 })
end

move_down 50

stroke_color "d8d8d8"

bounding_box [0,560], :width => 170, :height => 150 do
  move_down 1

  text "Supplier", align: :left, style: :bold, size: 18
  move_down 4


data = [["#{@purchase_order.supplier.firstname} #{@purchase_order.supplier.lastname}"]]

if @purchase_order.supplier.attributes["company"] and @purchase_order.supplier.attributes["company"].size > 0
  data << [@purchase_order.supplier.company]
end

data << [@purchase_order.supplier.address1]

if @purchase_order.supplier.address2.size > 0
  data << [@purchase_order.supplier.address2]
end

if @purchase_order.supplier.attributes["address3"] and @purchase_order.supplier.attributes["address3"].size > 0
  data << [@purchase_order.supplier.address3]
end



data << ["#{@purchase_order.supplier.city}, #{@purchase_order.supplier.state} #{@purchase_order.supplier.zipcode}"]
data << [@purchase_order.supplier.country]

if @purchase_order.supplier.phone 
  phone_number = @purchase_order.supplier.phone

  if @purchase_order.supplier.attributes["intl_phone"] and @purchase_order.supplier.attributes["intl_phone"].size > 0 
    phone_number += " Intl: #{@purchase_order.supplier.intl_phone}"
  end

  data << ["Phone: #{phone_number}"]
end

if @purchase_order.supplier.attributes["fax"] and @purchase_order.supplier.attributes["fax"].size > 0
  fax_number = @purchase_order.supplier.fax

  if @purchase_order.supplier.attributes["intl_fax"] and @purchase_order.supplier.attributes["intl_fax"].size > 0
    fax_number += " Intl: #{@purchase_order.supplier.intl_fax}"
  end

  data << ["Fax: #{fax_number}"]
end

if @purchase_order.supplier.attributes["po_comments"] and @purchase_order.supplier.attributes["po_comments"].size > 0
  data << ["#{@purchase_order.supplier.po_comments}"]
end 


table data,
  :position => :center,
  :border_width => 0.5,
  :vertical_padding   => 1,
  :horizontal_padding => 0,
  :font_size => 9,
  :border_style => :underline_header,
  :column_widths => { 0 => 170 }


  stroke do
    line_width 0.5
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right

  end
end

bounding_box [180,560], :width => 170, :height => 150 do
  move_down 1

  text "Account / Rep", align: :left, style: :bold, size: 18
  move_down 4

  data = [["Number: #{@purchase_order.supplier.account_number}"]]

  unless @purchase_order.supplier.nr_account_number.blank?
    data << ["NR account: #{@purchase_order.supplier.nr_account_number}"]
  end

  data << ["Contact: #{@purchase_order.supplier_contact.name}"]
  
  unless @purchase_order.supplier_contact.phone.blank?
    data << ["Phone: #{@purchase_order.supplier_contact.phone}"]
  end

  unless @purchase_order.supplier_contact.email.blank?
    data << ["E-mail: #{@purchase_order.supplier_contact.email}"]
  end


  table data,
    :position => :center,
    :border_width => 0.5,
    :vertical_padding   => 1,
    :horizontal_padding => 0,
    :font_size => 9,
    :border_style => :underline_header,
    :column_widths => { 0 => 170 }

  stroke do
    line_width 0.5
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right
  end
end



bounding_box [370,560], :width => 170, :height => 150 do
  move_down 1

  text "Ship To", align: :left, style: :bold, size: 18
  move_down 4

data = [["#{ @purchase_order.address.firstname} #{ @purchase_order.address.lastname}"]]

if  @purchase_order.address.attributes["company"] and  @purchase_order.address.attributes["company"].size > 0
  data << [ @purchase_order.address.company]
end

data << [ @purchase_order.address.address1]

if  @purchase_order.address.address2.size > 0
  data << [ @purchase_order.address.address2]
end

if  @purchase_order.address.attributes["address3"] and  @purchase_order.address.attributes["address3"].size > 0
  data << [ @purchase_order.address.address3]
end

data << ["#{ @purchase_order.address.city}, #{ @purchase_order.address.state} #{ @purchase_order.address.zipcode}"]
data << [ @purchase_order.address.country]

if  @purchase_order.address.phone 
  phone_number =  @purchase_order.address.phone

  if  @purchase_order.address.attributes["intl_phone"] and  @purchase_order.address.attributes["intl_phone"].size > 0 
    phone_number += " Intl: #{ @purchase_order.address.intl_phone}"
  end

  data << ["Phone: #{phone_number}"]
end

if  @purchase_order.address.attributes["fax"] and  @purchase_order.address.attributes["fax"].size > 0
  fax_number =  @purchase_order.address.fax

  if  @purchase_order.address.attributes["intl_fax"] and  @purchase_order.address.attributes["intl_fax"].size > 0
    fax_number += " Intl: #{ @purchase_order.address.intl_fax}"
  end

  data << ["Fax: #{fax_number}"]
end

table data,
  :position => :center,
  :border_width => 0.5,
  :vertical_padding   => 1,
  :horizontal_padding => 0,
  :font_size => 9,
  :border_style => :underline_header,
  :column_widths => { 0 => 170 }

  move_down 4

  text "Method: #{@purchase_order.shipping_method.name}", align: :left, style: :bold, size: 9

  unless @purchase_order.due_at.blank?
    move_down 4
    text("DUE DATE: #{@purchase_order.due_at.strftime("%m/%d/%Y")}", style: :bold)
  end 


  stroke do
    line_width 0.5
    line bounds.top_right, bounds.bottom_right
    line bounds.bottom_left, bounds.bottom_right

  end

end



move_down 10
font "Helvetica", size: 18
text "#{@purchase_order.created_at.strftime("%m/%d/%Y")} - #{@purchase_order.id} - #{@purchase_order.user.email.split("@").first.titleize}"

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

  bounding_box [0,285], :width => 540 do
    #move_down 2
    content = []
    @purchase_order.purchase_order_line_items.each do |item|
      row = [ item.variant.sku, item.variant.product.name.split(":").first + " - " + (item.returnable ? "Returnable" : "Non-returnable")]
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
      :border_width => 0,
      :vertical_padding   => 3,
      :horizontal_padding => 6,
      :column_widths => { 0 => 100, 1 => 225, 2 => 65, 3 => 75, 4 => 75 },
      :font_size => 9, 
      :align => { 0 => :left, 1 => :left, 2 => :right, 3 => :right, 4 => :right }

  end

  font "Helvetica", :size => 9

  totals = []

  totals << [Prawn::Table::Cell.new( :text => "Sub-total", :font_style => :bold), number_to_currency(@purchase_order.gross_amount)]
  totals << [Prawn::Table::Cell.new( :text => "Tax", :font_style => :bold), number_to_currency(@purchase_order.tax.to_f)]
  totals << [Prawn::Table::Cell.new( :text => "Shipping", :font_style => :bold), number_to_currency(@purchase_order.shipping.to_f)]
  totals << [Prawn::Table::Cell.new( :text => "Total", :font_style => :bold), number_to_currency(@purchase_order.total)]

  bounding_box [bounds.right - 310, bounds.bottom + (totals.length * 18)], :width => 300 do
    table totals,
      :position => :right,
      :border_width => 0,
      :vertical_padding   => 2,
      :horizontal_padding => 6,
      :font_size => 10,
      :column_widths => { 0 => 225, 1 => 75 } ,
      :align => { 0 => :right, 1 => :right }

  end

  bounding_box [10, 50], :width => 175, height: 40 do
    unless @purchase_order.comments.blank?
      font "Helvetica", size: 12
      text "COMMENTS:"
      font "Helvetica", size: 10
      text @purchase_order.comments
    end
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

pdf.render_file(File.join(Rails.root, "tmp", "pdfs", @purchase_order.number + ".pdf"))
