FactoryGirl.define do
  factory :purchase_order, :class => Spree::PurchaseOrder do
    # associations:
    association(:user, :factory => :user)
    association(:address, :factory => :address)
    association(:shipping_method, :factory => :shipping_method)
    entered_at nil
    submitted_at nil
    received_at nil
    completed_at nil
    status "New"

  end

  factory :purchase_order_with_line_items, :parent => :purchase_order do
    after_create { |purchase_order| FactoryGirl.create(:purchase_order_line_item, :purchase_order => purchase_order) }
  end

  factory :entered_purchase_order, parent: :purchase_order_with_line_items do
    entered_at Time.current
    status "Entered"
  end

  factory :submitted_purchase_order, parent: :entered_purchase_order do
    submitted_at Time.current
    status "Submitted"
  end

end
