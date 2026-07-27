require "rails_helper"

RSpec.describe "Admin::DataExports", type: :request do
  describe "GET /admin/data_export" do
    it "全業務データと添付画像をBase64のdata URLとしてCSVに出力する" do
      plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
      plant.image.attach(
        io: StringIO.new("image data"),
        filename: "plant.txt",
        content_type: "text/plain"
      )
      location = Location.create!(name: "テストロケーション", code: "loc", prefix: "LOC")
      stock = Stocks::Creator.call(
        plant_id: plant.id,
        location_id: location.id,
        growing_method: "pot",
        propagation_method: "seed"
      )
      StockObservation.create!(stock:, height_cm: 12.5, memo: "元気")

      get admin_data_export_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers.fetch("Content-Disposition")).to include("attachment")

      rows = CSV.parse(response.body, headers: true)
      plant_row = rows.find { |row| row["record_type"] == "Plant" && row["record_id"] == plant.id.to_s }
      stock_row = rows.find { |row| row["record_type"] == "Stock" && row["record_id"] == stock.id.to_s }

      expect(JSON.parse(plant_row.fetch("attributes_json"))).to include("name" => "テストプラント")
      expect(plant_row.fetch("image_filename")).to eq("plant.txt")
      expect(plant_row.fetch("image_content_type")).to eq("text/plain")
      expect(plant_row.fetch("image_byte_size")).to eq("10")
      expect(plant_row.fetch("image_data_url")).to eq("data:text/plain;base64,aW1hZ2UgZGF0YQ==")
      expect(JSON.parse(stock_row.fetch("attributes_json"))).to include("plant_id" => plant.id, "location_id" => location.id)
    end
  end
end
