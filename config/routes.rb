Spree::Core::Engine.routes.draw do
 namespace :admin do
    resources :purchase_orders do
      collection do
        get 'inventory_report'
        get 'open_dropship_report'

      end

      match 'edit_line_items'
      match 'submit'
      match 'submitted'
      match 'complete'
      match 'source'
      match 'item'

    end

    resources :purchase_order_line_items

    resources :supplier_contacts
    resources :suppliers do
      collection do
        post 'pricing_for_variant'
        get 'inventory_report'
      end
    end

    get 'manage_stock' => 'manage_stock#index', as: 'manage_stock'
    get 'manage_stock/full_inventory_report' => 'manage_stock#full_inventory_report',
      as: 'full_inventory_report'

    get 'manage_stock/update_by_sku' => 'manage_stock#update_by_sku', 
      as: 'update_by_sku'
    
    get 'manage_stock/last_scanned_at' => 'manage_stock#last_scanned_at', 
      as: 'last_scanned_at'
    
    post 'manage_stock/update_sku' => 'manage_stock#update_sku', 
      as: 'update_sku'

    match 'manage_stock/update' => 'manage_stock#update',
      as: 'stock_update'

    match 'manage_stock/:purchase_order_id/receive_entire_po' => 'manage_stock#receive_entire_po',
      as: 'receive_entire_po'
    
    get "advanced_inventory_settings" => "advanced_inventory_settings#show",
      as: "advanced_inventory_settings"

    get "advanced_inventory_settings/edit" => "advanced_inventory_settings#edit",
      as: "edit_advanced_inventory_settings"

    put "advanced_inventory_settings" => "advanced_inventory_settings#update"
  end

end
