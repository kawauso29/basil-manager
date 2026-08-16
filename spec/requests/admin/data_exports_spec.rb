require "rails_helper"
require "csv"
require "zip"

RSpec.describe "Admin::DataExports", type: :request do
  describe "GET /admin/data_export" do
    it "AIへ提供する生産管理レコードとPlant・Location・StockObservationの画像をZIPへ出力する" do
      plant = Plant.create!(
        name: "テストプラント",
        code: "test",
        scientific_name: "Ocimum basilicum"
      )
      plant.image.attach(
        io: StringIO.new("plant image"),
        filename: "plant.txt",
        content_type: "text/plain"
      )
      location = Location.create!(
        name: "テストロケーション",
        code: "loc",
        environment: "outdoor"
      )
      location.image.attach(
        io: StringIO.new("location image"),
        filename: "location.txt",
        content_type: "text/plain"
      )
      production_lot = ProductionLot.create!(
        plant: plant,
        propagation_method: "seed",
        started_on: Date.new(2026, 8, 14),
        initial_quantity: 2,
        memo: "播種から開始"
      )
      nursery_group = NurseryGroup.create!(
        production_lot: production_lot,
        location: location,
        stage: "pot_up_ready",
        growing_method: "soil",
        container_type: "cell_tray",
        quantity: 1,
        stage_started_on: Date.new(2026, 8, 20),
        memo: "鉢上げ待ち"
      )
      stock = Stock.create!(
        plant: plant,
        location: location,
        source_nursery_group: nursery_group,
        stage: "acclimating",
        stage_started_on: Date.new(2026, 8, 21),
        potted_on: Date.new(2026, 8, 21),
        memo: "南側で管理"
      )
      observation = StockObservation.create!(
        stock: stock,
        height_cm: 12.5,
        memo: "元気",
        recorded_at: Time.zone.local(2026, 8, 25, 8)
      )
      observation.image.attach(
        io: StringIO.new("growth image"),
        filename: "growth.txt",
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
        plant_row = find_row(rows, Plant, plant.id)
        location_row = find_row(rows, Location, location.id)
        production_lot_row = find_row(rows, ProductionLot, production_lot.id)
        nursery_group_row = find_row(rows, NurseryGroup, nursery_group.id)
        stock_row = find_row(rows, Stock, stock.id)
        observation_row = find_row(rows, StockObservation, observation.id)

        expect(rows.headers).to include("image_path")
        expect(rows.headers).not_to include("image_data_url")
        expect(rows.map { |row| row.fetch("record_type") }).to contain_exactly(
          "Plant",
          "Location",
          "ProductionLot",
          "NurseryGroup",
          "Stock",
          "StockObservation"
        )
        expect([
          plant_row,
          location_row,
          production_lot_row,
          nursery_group_row,
          stock_row
        ]).to all(
          satisfy do |row|
            row.fetch("record_role") == "main" &&
              row.fetch("main_record_type") == row.fetch("record_type") &&
              row.fetch("main_record_id") == row.fetch("record_id") &&
              row["association_name"].nil?
          end
        )

        expect(JSON.parse(plant_row.fetch("attributes_json"))).to include(
          "name" => "テストプラント",
          "scientific_name" => "Ocimum basilicum"
        )
        expect(JSON.parse(location_row.fetch("attributes_json"))).to include(
          "environment" => "outdoor"
        )
        expect(JSON.parse(production_lot_row.fetch("attributes_json"))).to include(
          "plant_id" => plant.id,
          "propagation_method" => "seed",
          "initial_quantity" => 2
        )
        expect(JSON.parse(nursery_group_row.fetch("attributes_json"))).to include(
          "production_lot_id" => production_lot.id,
          "location_id" => location.id,
          "stage" => "pot_up_ready",
          "quantity" => 1
        )
        expect(JSON.parse(stock_row.fetch("attributes_json"))).to include(
          "plant_id" => plant.id,
          "location_id" => location.id,
          "source_nursery_group_id" => nursery_group.id,
          "stage" => "acclimating",
          "memo" => "南側で管理"
        )
        expect(JSON.parse(observation_row.fetch("attributes_json"))).to include(
          "stock_id" => stock.id,
          "height_cm" => "12.5",
          "memo" => "元気"
        )

        expect_image(
          archive,
          plant_row,
          "images/plants/#{plant.id}/plant.txt",
          "plant image"
        )
        expect_image(
          archive,
          location_row,
          "images/locations/#{location.id}/location.txt",
          "location image"
        )
        expect_image(
          archive,
          observation_row,
          "images/stocks/#{stock.id}/observations/#{observation.id}/growth.txt",
          "growth image"
        )
        expect([ production_lot_row, nursery_group_row, stock_row ]).to all(
          satisfy { |row| row["image_path"].nil? }
        )
      end
    end

    it "StockObservationを対応するStockの直後に出力する" do
      plant = Plant.create!(name: "観察用プラント", code: "observation-plant")
      location = Location.create!(name: "観察用ロケーション", code: "observation-location")
      stock = Stock.create!(
        plant: plant,
        location: location,
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 20)
      )
      observation = StockObservation.create!(
        stock: stock,
        memo: "葉色良好",
        recorded_at: Time.zone.local(2026, 8, 25, 9)
      )

      get admin_data_export_path, headers: admin_headers

      open_archive do |archive|
        rows = csv_rows(archive)
        row_indexes = rows.each_with_index.to_h do |row, index|
          [ [ row.fetch("record_type"), row.fetch("record_id") ], index ]
        end
        stock_row_index = row_indexes.fetch([ "Stock", stock.id.to_s ])
        observation_row_index = row_indexes.fetch([ "StockObservation", observation.id.to_s ])
        observation_row = rows[observation_row_index]

        expect(observation_row_index).to eq(stock_row_index + 1)
        expect(observation_row.to_h).to include(
          "record_role" => "log",
          "main_record_type" => "Stock",
          "main_record_id" => stock.id.to_s,
          "association_name" => "stock_observations"
        )
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
