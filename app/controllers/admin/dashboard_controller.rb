class Admin::DashboardController < Admin::BaseController
  def index
    active_stocks = Stock.active.includes(:plant, location: :location_observations)
    @stock_summary = Admin::StockSummaryPresenter.call(active_stocks)
    @registered_plant_count = Plant.count
    @registered_location_count = Location.count
    @latest_location_observations = latest_location_observations
  end

  private

  def latest_location_observations
    locations = @stock_summary.location_rows.map { |row| row[:record] }

    locations.to_h do |location|
      [ location.id, location.latest_observation ]
    end
  end
end
