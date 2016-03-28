module Spree
  class Admin::AdvancedInventorySettingsController < Admin::BaseController

    def show
      if not Spree::Config.advanced_inventory_office_address1 and
        not Spree::Config.advanced_inventory_tax_id

        redirect_to admin_edit_advanced_inventory_settings_path,
          notice: "Please enter the office address and tax ID of your company"
      end
    end

    def edit
    end

    def update

      Spree::Config.advanced_inventory_office_company = params[:advanced_inventory_office_company]
      Spree::Config.advanced_inventory_office_address1 = params[:advanced_inventory_office_address1]
      Spree::Config.advanced_inventory_office_address2  = params[:advanced_inventory_office_address2]
      Spree::Config.advanced_inventory_office_phone = params[:advanced_inventory_office_phone]
      Spree::Config.advanced_inventory_office_email = params[:advanced_inventory_office_email]
      Spree::Config.advanced_inventory_office_city = params[:advanced_inventory_office_city]
      Spree::Config.advanced_inventory_office_state = params[:advanced_inventory_office_state]
      Spree::Config.advanced_inventory_office_zip = params[:advanced_inventory_office_zip]
      Spree::Config.advanced_inventory_office_country = params[:advanced_inventory_office_country]
      Spree::Config.advanced_inventory_tax_id = params[:advanced_inventory_tax_id]


      redirect_to admin_advanced_inventory_settings_path, success: "Ingram Settings Saved"

    end
  end
end
