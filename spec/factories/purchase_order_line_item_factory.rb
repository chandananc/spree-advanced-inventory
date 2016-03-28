FactoryGirl.define do
  factory :purchase_order_line_item, :class => Spree::PurchaseOrderLineItem do
    quantity 1
    price { BigDecimal.new('10.00') }

    # associations:
    association(:purchase_orderorder, :factory => :purchase_order)
    association(:variant, :factory => :variant)
  end
end
