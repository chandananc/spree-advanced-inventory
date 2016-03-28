Spree::Admin::BaseController.class_eval do
  helper_method :ship_velocities

  def ship_velocities
    { 
      1 => "Ships in a week or less",
      2 => "Ships within one month",
      3 => "Ships within three months",
      4 => "Ships in 3+ months"
    }
  end
end