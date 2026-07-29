require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "育成中Stockの全体集計と植物・ロケーション別内訳を表示する" do
      plant = Plant.create!(name: "ダッシュボード植物", code: "dashboard-plant", prefix: "DBP")
      unused_plant = Plant.create!(name: "未保有の植物", code: "unused-plant", prefix: "UNP")
      location = Location.create!(name: "ダッシュボード場所", code: "dashboard-location", prefix: "DBL")
      unused_location = Location.create!(name: "未使用の場所", code: "unused-location", prefix: "UNL")
      stock = Stocks::Creator.call(
        plant_id: plant.id,
        location_id: location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 3
      )
      stock.update!(status: "growing")
      completed_stock = Stocks::Creator.call(
        plant_id: unused_plant.id,
        location_id: unused_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 8
      )
      completed_stock.update!(
        completed_at: Time.zone.local(2026, 7, 1, 10),
        completion_reason: "harvested"
      )
      LocationObservation.create!(
        location: location,
        temperature: 24.5,
        weather: "sunny",
        memo: "最新の場所記録",
        recorded_at: Time.zone.local(2026, 7, 28, 8)
      )

      get admin_root_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      cards = document.css(".summary-card").to_h do |card|
        [ card.at_css("dt").text.strip, card.at_css("dd").text.squish ]
      end

      expect(cards).to include(
        "管理株数" => "3 株",
        "管理単位数" => "1 件",
        "管理植物種数" => "1 種",
        "使用ロケーション数" => "1 か所"
      )
      expect(document.at_css(".summary-lead").text.squish).to include(
        "1種類",
        "1管理単位・3株",
        "1か所"
      )
      expect(response.body).to include("生育中 3株")
      expect(response.body).to include(
        admin_plant_path(plant),
        admin_location_path(location),
        "24.5",
        "最新の環境記録"
      )
      expect(response.body).not_to include(admin_plant_path(unused_plant))
      expect(response.body).not_to include(admin_location_path(unused_location))
    end
  end
end
