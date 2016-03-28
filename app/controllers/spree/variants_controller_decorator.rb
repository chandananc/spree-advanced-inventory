Spree::Admin::VariantsController.class_eval do
  def search
    search_params = { :product_name_cont => params[:q], :sku_cont => params[:q] }
    @variants = Spree::Variant.where(deleted_at: nil, is_master: false).order("id desc").ransack(search_params.merge(:m => 'or')).result
  end
end
