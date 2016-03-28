require 'spec_helper'

describe Spree::PurchaseOrder do
  let(:address) { stub_model(Spree::Address) }
  let(:order) { stub_model(Spree::Order) }
  let(:user) { stub_model(Spree::User) }
  let(:purchase_order) { stub_model(Spree::PurchaseOrder) }
  let(:shipping_method) { stub_model(Spree::ShippingMethod) }
  let(:purchase_order_line_item1) { stub_model(Spree::PurchaseOrderLineItem) }
  let(:purchase_order_line_item2) { stub_model(Spree::PurchaseOrderLineItem) }
  let(:inventory_unit) { stub_model(Spree::InventoryUnit) }

  before :each do
    order.stub(:user => user)
    order.stub(:address => address)
    order.stub(:state => "complete")

    @variant1 = mock_model(Spree::Variant, 
                           :product => "product1", 
                           on_hand: 1, 
                           count_on_hand: 1)

    @line_items = [mock_model(Spree::LineItem, 
                              :variant => @variant1, 
                              :variant_id => @variant1.id, 
                              :quantity => 1)]    

    inventory_unit.stub(:variant_id => @variant1.id)
    inventory_unit.stub(:order_id => order.id)
    inventory_unit.stub(:save => true)
    inventory_unit.stub(:fill_backorder => true)

    order.stub(:line_items => @line_items)
  end

  context "#items_received" do

  end

  context "#fill_order_backorders" do
    context "quantity left is greater than zero" do
      it "fills inventory_unit backorders" do

      end
    end

    context "backorder adjustment is greater than 0" do

    end
  end

  context "#stock_remaining_units" do
    
    context "quantity is greater than zero" do
      it "receives variant stock" do
        @variant1.should_receive(:receive).with(1)
        purchase_order.stock_remaining_units(@variant1, 1)
      end
    end

    context "quantity is zero" do
      it "does not receive variant stock" do
        @variant1.should_not_receive(:receive)
        purchase_order.stock_remaining_units(@variant1, 0)

      end
    end
  end

end
