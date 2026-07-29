require "rails_helper"

RSpec.describe Admin::StockSummaryPresenter do
  describe ".call" do
    it "渡された育成中Stockを管理単位数と実株数に分けて集計する" do
      plant = Plant.create!(name: "集計対象の植物", code: "summary-plant", prefix: "SMP")
      other_plant = Plant.create!(name: "別の集計対象植物", code: "other-summary-plant", prefix: "OSP")
      location = Location.create!(name: "集計対象の場所", code: "summary-location", prefix: "SML")
      other_location = Location.create!(name: "別の集計対象場所", code: "other-summary-location", prefix: "OSL")

      stock = Stocks::Creator.call(
        plant_id: plant.id,
        location_id: location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 3
      )
      stock.update!(status: "growing")
      Stocks::Creator.call(
        plant_id: plant.id,
        location_id: other_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 2
      )
      Stocks::Creator.call(
        plant_id: other_plant.id,
        location_id: location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 4
      )

      summary = described_class.call(
        Stock.active.includes(:plant, :location).order(:id).load
      )

      expect(summary.management_unit_count).to eq(3)
      expect(summary.quantity).to eq(9)
      expect(summary.plant_count).to eq(2)
      expect(summary.location_count).to eq(2)
      expect(summary.status_rows).to contain_exactly(
        {
          key: "starting",
          label: Stock.statuses_i18n.fetch("starting"),
          management_unit_count: 2,
          quantity: 6
        },
        {
          key: "growing",
          label: Stock.statuses_i18n.fetch("growing"),
          management_unit_count: 1,
          quantity: 3
        }
      )

      plant_row = summary.plant_rows.find { |row| row[:record] == plant }
      expect(plant_row).to include(
        management_unit_count: 2,
        quantity: 5,
        location_count: 2
      )
      expect(plant_row[:locations]).to contain_exactly(location, other_location)
      expect(plant_row[:status_rows].pluck(:key)).to contain_exactly("starting", "growing")

      location_row = summary.location_rows.find { |row| row[:record] == location }
      expect(location_row).to include(
        management_unit_count: 2,
        quantity: 7,
        plant_count: 2
      )
      expect(location_row[:plants]).to contain_exactly(plant, other_plant)
      expect(location_row[:status_rows].pluck(:key)).to contain_exactly("starting", "growing")
    end

    it "Stockがなければすべて0と空の内訳を返す" do
      summary = described_class.call([])

      expect(summary.management_unit_count).to eq(0)
      expect(summary.quantity).to eq(0)
      expect(summary.plant_count).to eq(0)
      expect(summary.location_count).to eq(0)
      expect(summary.status_rows).to eq([])
      expect(summary.plant_rows).to eq([])
      expect(summary.location_rows).to eq([])
    end
  end
end
