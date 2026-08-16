require "rails_helper"

RSpec.describe "Admin::Plants", type: :request do
  let!(:location) do
    Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")
  end

  describe "GET /admin/plants" do
    it "植物をコードと名前で一覧表示する" do
      plant = Plant.create!(name: "バジル", code: "basil", scientific_name: "Ocimum basilicum")

      get admin_plants_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(plant.name, plant.code)
      expect(response.body).not_to include("プレフィックス", "最終株番号")
    end
  end

  describe "GET /admin/plants/:id" do
    it "関連するLotとStockを表示する" do
      plant = Plant.create!(name: "バジル", code: "basil")
      production_lot = StartProduction.call(
        plant_id: plant.id,
        propagation_method: "seed",
        started_on: Date.new(2026, 8, 14),
        initial_quantity: 5,
        location_id: location.id,
        growing_method: "soil"
      )
      stock = Stock.register_direct!(
        plant_id: plant.id,
        location_id: location.id,
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 14)
      )

      get admin_plant_path(plant), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("LOT-#{production_lot.id}", "ST-#{stock.id}")
    end
  end

  describe "GET /admin/plants/new and /admin/plants/:id/edit" do
    it "作成・編集フォームに現在のマスタ項目だけを表示する" do
      plant = Plant.create!(name: "バジル", code: "basil")

      [ new_admin_plant_path, edit_admin_plant_path(plant) ].each do |path|
        get path, headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          'name="plant[name]"',
          'name="plant[code]"',
          'name="plant[scientific_name]"'
        )
        expect(response.body).not_to include(
          'name="plant[prefix]"',
          'name="plant[last_stock_number]"'
        )
      end
    end
  end

  describe "POST /admin/plants" do
    it "植物を作成する" do
      expect {
        post admin_plants_path,
             params: {
               plant: {
                 name: "バジル",
                 code: "basil",
                 scientific_name: "Ocimum basilicum"
               }
             },
             headers: admin_headers
      }.to change(Plant, :count).by(1)

      plant = Plant.last
      expect(response).to redirect_to(admin_plant_path(plant))
      expect(plant).to have_attributes(name: "バジル", code: "basil")
    end

    it "コードが空なら作成しない" do
      expect {
        post admin_plants_path,
             params: { plant: { name: "バジル", code: "" } },
             headers: admin_headers
      }.not_to change(Plant, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/plants/:id" do
    it "植物を更新する" do
      plant = Plant.create!(name: "バジル", code: "basil")

      patch admin_plant_path(plant),
            params: {
              plant: {
                name: "スイートバジル",
                code: "sweet-basil",
                scientific_name: "Ocimum basilicum"
              }
            },
            headers: admin_headers

      expect(response).to redirect_to(admin_plant_path(plant))
      expect(plant.reload).to have_attributes(name: "スイートバジル", code: "sweet-basil")
    end
  end

  describe "DELETE /admin/plants/:id" do
    it "関連データがなければ削除する" do
      plant = Plant.create!(name: "削除対象", code: "delete-target")

      expect {
        delete admin_plant_path(plant), headers: admin_headers
      }.to change(Plant, :count).by(-1)

      expect(response).to redirect_to(admin_plants_path)
    end

    it "Lotから参照されている植物は削除しない" do
      plant = Plant.create!(name: "バジル", code: "basil")
      StartProduction.call(
        plant_id: plant.id,
        propagation_method: "seed",
        started_on: Date.new(2026, 8, 14),
        initial_quantity: 5,
        location_id: location.id,
        growing_method: "soil"
      )

      expect {
        delete admin_plant_path(plant), headers: admin_headers
      }.not_to change(Plant, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "Stockから参照されている植物は削除しない" do
      plant = Plant.create!(name: "購入株の植物", code: "purchased-plant")
      Stock.register_direct!(
        plant_id: plant.id,
        location_id: location.id,
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 14)
      )

      expect {
        delete admin_plant_path(plant), headers: admin_headers
      }.not_to change(Plant, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
