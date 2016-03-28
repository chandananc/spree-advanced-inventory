Spree::Address.class_eval do
  def self.eligible_for_po(po)
    find_by_sql(["select a.* 
                 from spree_addresses a, spree_orders o, spree_line_items l 
                 where 
                 o.is_dropship = true and 
                 o.completed_at is not null and 
                 (o.state = 'resumed' or o.state = 'complete') and 
                 l.order_id = o.id and
                 (a.id = o.ship_address_id and 
                 l.variant_id in (select distinct(variant_id) from spree_purchase_order_line_items where purchase_order_id = ?) or 
                 a.id = ?)
                 group by a.id 
                 order by a.lastname asc, a.firstname asc", po.id, po.address_id])  
  end
end
