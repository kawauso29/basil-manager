require "rails_helper"

RSpec.describe "Admin::DataExports", type: :request do
  describe "GET /admin/data_export" do
    it "Location・Plant・Stockの最新カラムと添付画像をCSVに出力する" do
      plant = Plant.create!(
        name: "テストプラント",
        code: "test",
        prefix: "TST",
        watering_guide: "土の表面が乾いたらたっぷり",
        care_cautions: "冬の過湿に注意"
      )
      plant.image.attach(
        io: StringIO.new("image data"),
        filename: "plant.txt",
        content_type: "text/plain"
      )
      location = Location.create!(
        name: "テストロケーション",
        code: "loc",
        prefix: "LOC",
        environment: "outdoor"
      )
      stock = Stocks::Creator.call(
        plant_id: plant.id,
        location_id: location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 3,
        memo: "3株をまとめて管理",
        label: "南側バジル"
      )

      get admin_data_export_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers.fetch("Content-Disposition")).to include("attachment")

      rows = CSV.parse(response.body, headers: true)
      location_row = rows.find { |row| row["record_type"] == "Location" && row["record_id"] == location.id.to_s }
      plant_row = rows.find { |row| row["record_type"] == "Plant" && row["record_id"] == plant.id.to_s }
      stock_row = rows.find { |row| row["record_type"] == "Stock" && row["record_id"] == stock.id.to_s }

      expect(rows.map { |row| row.fetch("record_type") }).to include("Location", "Plant", "Stock")
      expect([ location_row, plant_row, stock_row ]).to all(
        satisfy do |row|
          row.fetch("record_role") == "main" &&
            row.fetch("main_record_type") == row.fetch("record_type") &&
            row.fetch("main_record_id") == row.fetch("record_id") &&
            row["association_name"].nil?
        end
      )
      expect(JSON.parse(location_row.fetch("attributes_json"))).to include("environment" => "outdoor")
      expect(JSON.parse(plant_row.fetch("attributes_json"))).to include(
        "name" => "テストプラント",
        "watering_guide" => "土の表面が乾いたらたっぷり",
        "care_cautions" => "冬の過湿に注意"
      )
      expect(plant_row.fetch("image_filename")).to eq("plant.txt")
      expect(plant_row.fetch("image_content_type")).to eq("text/plain")
      expect(plant_row.fetch("image_byte_size")).to eq("10")
      expect(plant_row.fetch("image_data_url")).to eq("data:text/plain;base64,aW1hZ2UgZGF0YQ==")
      expect(JSON.parse(stock_row.fetch("attributes_json"))).to include(
        "plant_id" => plant.id,
        "location_id" => location.id,
        "quantity" => 3,
        "memo" => "3株をまとめて管理",
        "label" => "南側バジル"
      )
    end

    it "観察記録と操作ログを関連する主レコードの直後に出力する" do
      plant = Plant.create!(name: "ログ用プラント", code: "log-plant", prefix: "LGP")
      location = Location.create!(name: "ログ用ロケーション", code: "log-location", prefix: "LGL")
      stock = Stocks::Creator.call(
        plant_id: plant.id,
        location_id: location.id,
        growing_method: "pot",
        quantity: 2
      )
      location_observation = LocationObservation.create!(
        location:,
        temperature: 24.5,
        weather: "sunny",
        memo: "風通し良好"
      )
      stock.change_quantity!(quantity: 4, memo: "株分け")
      stock_action_log = stock.stock_action_logs.find_by!(action_type: "quantity_changed")
      stock_observation = StockObservation.create!(stock:, height_cm: 12.5, memo: "元気")
      stock_observation.image.attach(
        io: StringIO.new("growth image"),
        filename: "growth.txt",
        content_type: "text/plain"
      )

      get admin_data_export_path, headers: admin_headers

      rows = CSV.parse(response.body, headers: true)
      row_indexes = rows.each_with_index.to_h do |row, index|
        [ [ row.fetch("record_type"), row.fetch("record_id") ], index ]
      end
      location_row_index = row_indexes.fetch([ "Location", location.id.to_s ])
      location_log_index = row_indexes.fetch([ "LocationObservation", location_observation.id.to_s ])
      stock_row_index = row_indexes.fetch([ "Stock", stock.id.to_s ])
      stock_action_log_index = row_indexes.fetch([ "StockActionLog", stock_action_log.id.to_s ])
      stock_observation_index = row_indexes.fetch([ "StockObservation", stock_observation.id.to_s ])

      expect(location_log_index).to eq(location_row_index + 1)
      expect(stock_action_log_index).to eq(stock_row_index + 1)
      expect(stock_observation_index).to eq(stock_action_log_index + 1)

      location_log_row = rows[location_log_index]
      stock_action_log_row = rows[stock_action_log_index]
      stock_observation_row = rows[stock_observation_index]

      expect(location_log_row.to_h).to include(
        "record_role" => "log",
        "main_record_type" => "Location",
        "main_record_id" => location.id.to_s,
        "association_name" => "location_observations"
      )
      expect(JSON.parse(location_log_row.fetch("attributes_json"))).to include(
        "location_id" => location.id,
        "temperature" => "24.5",
        "weather" => "sunny",
        "memo" => "風通し良好"
      )
      expect(stock_action_log_row.to_h).to include(
        "record_role" => "log",
        "main_record_type" => "Stock",
        "main_record_id" => stock.id.to_s,
        "association_name" => "stock_action_logs"
      )
      expect(JSON.parse(stock_action_log_row.fetch("attributes_json"))).to include(
        "stock_id" => stock.id,
        "action_type" => "quantity_changed",
        "quantity_before" => 2,
        "quantity_after" => 4
      )
      expect(stock_observation_row.to_h).to include(
        "record_role" => "log",
        "main_record_type" => "Stock",
        "main_record_id" => stock.id.to_s,
        "association_name" => "stock_observations",
        "image_filename" => "growth.txt",
        "image_data_url" => "data:text/plain;base64,Z3Jvd3RoIGltYWdl"
      )
    end
  end
end
