class Admin::StockSummaryPresenter
  attr_reader :management_unit_count,
              :quantity,
              :plant_count,
              :location_count,
              :status_rows,
              :plant_rows,
              :location_rows

  def self.call(stocks)
    new(stocks).call
  end

  def initialize(stocks)
    @stocks = stocks.to_a
  end

  def call
    @management_unit_count = @stocks.size
    @quantity = @stocks.sum(&:quantity)
    @plant_count = @stocks.map(&:plant_id).uniq.size
    @location_count = @stocks.map(&:location_id).uniq.size
    @status_rows = build_status_rows(@stocks)
    @plant_rows = build_plant_rows
    @location_rows = build_location_rows
    self
  end

  private

  def build_status_rows(stocks)
    stocks_by_status = stocks.group_by(&:status)

    Stock.statuses.keys.filter_map do |status|
      stocks = stocks_by_status[status]
      next if stocks.blank?

      {
        key: status,
        label: Stock.statuses_i18n.fetch(status),
        management_unit_count: stocks.size,
        quantity: stocks.sum(&:quantity)
      }
    end
  end

  def build_plant_rows
    @stocks.group_by(&:plant).map do |plant, stocks|
      {
        record: plant,
        management_unit_count: stocks.size,
        quantity: stocks.sum(&:quantity),
        location_count: stocks.map(&:location_id).uniq.size,
        locations: stocks.map(&:location).uniq.sort_by(&:name),
        status_rows: build_status_rows(stocks)
      }
    end.sort_by { |row| row[:record].name }
  end

  def build_location_rows
    @stocks.group_by(&:location).map do |location, stocks|
      {
        record: location,
        management_unit_count: stocks.size,
        quantity: stocks.sum(&:quantity),
        plant_count: stocks.map(&:plant_id).uniq.size,
        plants: stocks.map(&:plant).uniq.sort_by(&:name),
        status_rows: build_status_rows(stocks)
      }
    end.sort_by { |row| row[:record].name }
  end
end
