require "rails_helper"
require "csv"
require "zip"

RSpec.describe "Admin::DataExports", type: :request do
  describe "GET /admin/data_export" do
    it "通常のCSVとLocation・Plant・Stockの画像をZIPに出力する" do
      plant = Plant.create!(
        name: "テストプラント",
        code: "test",
        prefix: "TST",
        watering_guide: "土の表面が乾いたらたっぷり",
        care_cautions: "冬の過湿に注意"
      )
      plant.image.attach(
        io: StringIO.new("plant image"),
        filename: "plant.txt",
        content_type: "text/plain"
      )
      location = Location.create!(
        name: "テストロケーション",
        code: "loc",
        prefix: "LOC",
        environment: "outdoor"
      )
      location.image.attach(
        io: StringIO.new("location image"),
        filename: "location.txt",
        content_type: "text/plain"
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
      stock.image.attach(
        io: StringIO.new("stock image"),
        filename: "stock.txt",
        content_type: "text/plain"
      )

      get admin_data_export_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/zip")
      expect(response.headers.fetch("Content-Disposition")).to include(
        "attachment",
        ".zip"
      )

      open_archive do |archive|
        rows = csv_rows(archive)
        location_row = find_row(rows, Location, location.id)
        plant_row = find_row(rows, Plant, plant.id)
        stock_row = find_row(rows, Stock, stock.id)

        expect(rows.headers).to include("image_path")
        expect(rows.headers).not_to include("image_data_url")
        expect(rows.map { |row| row.fetch("record_type") }).to include(
          "Location",
          "Plant",
          "Stock"
        )
        expect([ location_row, plant_row, stock_row ]).to all(
          satisfy do |row|
            row.fetch("record_role") == "main" &&
              row.fetch("main_record_type") == row.fetch("record_type") &&
              row.fetch("main_record_id") == row.fetch("record_id") &&
              row["association_name"].nil?
          end
        )
        expect(JSON.parse(location_row.fetch("attributes_json"))).to include(
          "environment" => "outdoor"
        )
        expect(JSON.parse(plant_row.fetch("attributes_json"))).to include(
          "name" => "テストプラント",
          "watering_guide" => "土の表面が乾いたらたっぷり",
          "care_cautions" => "冬の過湿に注意"
        )
        expect(JSON.parse(stock_row.fetch("attributes_json"))).to include(
          "plant_id" => plant.id,
          "location_id" => location.id,
          "quantity" => 3,
          "memo" => "3株をまとめて管理",
          "label" => "南側バジル"
        )

        expect_image(
          archive,
          location_row,
          "images/locations/#{location.id}/location.txt",
          "location image"
        )
        expect_image(
          archive,
          plant_row,
          "images/plants/#{plant.id}/plant.txt",
          "plant image"
        )
        expect_image(
          archive,
          stock_row,
          "images/stocks/#{stock.id}/stock.txt",
          "stock image"
        )
      end
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
        location: location,
        temperature: 24.5,
        weather: "sunny",
        memo: "風通し良好"
      )
      stock.change_quantity!(quantity: 4, memo: "株分け")
      stock_action_log = stock.stock_action_logs.find_by!(action_type: "quantity_changed")
      stock_observation = StockObservation.create!(stock: stock, height_cm: 12.5, memo: "元気")
      stock_observation.image.attach(
        io: StringIO.new("growth image"),
        filename: "growth.txt",
        content_type: "text/plain"
      )

      get admin_data_export_path, headers: admin_headers

      open_archive do |archive|
        rows = csv_rows(archive)
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

        expected_image_path =
          "images/stocks/#{stock.id}/observations/#{stock_observation.id}/growth.txt"
        expect(stock_observation_row.to_h).to include(
          "record_role" => "log",
          "main_record_type" => "Stock",
          "main_record_id" => stock.id.to_s,
          "association_name" => "stock_observations",
          "image_filename" => "growth.txt",
          "image_path" => expected_image_path
        )
        expect(archive.read(expected_image_path)).to eq("growth image")
      end
    end
  end

  def open_archive(&)
    Zip::File.open_buffer(StringIO.new(response.body), &)
  end

  def csv_rows(archive)
    csv = archive.read("data.csv").force_encoding(Encoding::UTF_8)
    CSV.parse(csv, headers: true)
  end

  def find_row(rows, record_type, record_id)
    rows.find do |row|
      row["record_type"] == record_type.name &&
        row["record_id"] == record_id.to_s
    end
  end

  def expect_image(archive, row, path, content)
    expect(row.to_h).to include(
      "image_filename" => File.basename(path),
      "image_content_type" => "text/plain",
      "image_byte_size" => content.bytesize.to_s,
      "image_path" => path
    )
    expect(archive.read(path)).to eq(content)
  end
end
