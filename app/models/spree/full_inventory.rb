module Spree
  class FullInventory < ActiveRecord::Base
    self.table_name =  "full_inventory" 

    def variant
      @v ||= Spree::Variant.find(id)

      return @v
    end
    
    def method_missing(m, *args, &block)
      variant.send("#{m.to_s}")
    end
  end
end
