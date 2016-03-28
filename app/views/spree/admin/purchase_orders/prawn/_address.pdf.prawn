data = [["#{address.firstname} #{address.lastname}"]]
data << [address.address1]

if address.address2.size > 0
  data << [address.address2]
end

if address.attributes["address3"] and address.attributes["address3"].size > 0
  data << [address.address3]
end


if address.attributes["company"] and address.attributes["company"].size > 0
  data << [address.company]
end

data << ["#{address.city}, #{address.state} #{address.zipcode}"]
data << [address.country]

if address.phone 
  phone_number = address.phone

  if address.attributes["intl_phone"] and address.attributes["intl_phone"].size > 0 
    phone_number += " Intl: #{address.intl_phone}"
  end

  data << ["Phone: #{phone_number}"]
end

if address.attributes["fax"] and address.attributes["fax"].size > 0
  fax_number = address.fax

  if address.attributes["intl_fax"] and address.attributes["intl_fax"].size > 0
    fax_number += " Intl: #{address.intl_fax}"
  end

  data << ["Fax: #{fax_number}"]
end

table data,
  :position => :center,
  :border_width => 0.5,
  :vertical_padding   => 1,
  :horizontal_padding => 0,
  :font_size => 10,
  :border_style => :underline_header,
  :column_widths => { 0 => 170 }

