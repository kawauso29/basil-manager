require "rails_helper"

RSpec.describe "Admin::Locations", type: :request do
  let!(:plant) { Plant.create!(name: "バジル", code: "basil") }

  describe "GET /admin/locations" do
    it "場所をコード、名前、環境で一覧表示する" do
      location = Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")

      get admin_locations_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(location.name, location.code, "屋内")
      expect(response.body).not_to include("プレフィックス")
    end
  end

  describe "GET /admin/locations/:id" do
    it "関連するGroupとStockを表示する" do
      location = Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")
      production_lot = StartProduction.call(
        plant_id: plant.id,
        propagation_method: "cutting",
        started_on: Date.new(2026, 8, 14),
        initial_quantity: 5,
        location_id: location.id,
        growing_method: "water"
      )
      nursery_group = production_lot.nursery_groups.first
      stock = Stock.register_direct!(
        plant_id: plant.id,
        location_id: location.id,
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 14)
      )

      get admin_location_path(location), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("NG-#{nursery_group.id}", "ST-#{stock.id}")
    end
  end

  describe "GET /admin/locations/new and /admin/locations/:id/edit" do
    it "作成・編集フォームにprefix入力を表示しない" do
      location = Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")

      [ new_admin_location_path, edit_admin_location_path(location) ].each do |path|
        get path, headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          'name="location[name]"',
          'name="location[code]"',
          'name="location[environment]"'
        )
        expect(response.body).not_to include('name="location[prefix]"')
      end
    end
  end

  describe "POST /admin/locations" do
    it "場所を作成する" do
      expect {
        post admin_locations_path,
             params: {
               location: {
                 name: "育成棚",
                 code: "growing-shelf",
                 environment: "indoor"
               }
             },
             headers: admin_headers
      }.to change(Location, :count).by(1)

      location = Location.last
      expect(response).to redirect_to(admin_location_path(location))
      expect(location).to have_attributes(
        name: "育成棚",
        code: "growing-shelf",
        environment: "indoor"
      )
    end

    it "コードが空なら作成しない" do
      expect {
        post admin_locations_path,
             params: {
               location: {
                 name: "育成棚",
                 code: "",
                 environment: "indoor"
               }
             },
             headers: admin_headers
      }.not_to change(Location, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/locations/:id" do
    it "場所を更新する" do
      location = Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")

      patch admin_location_path(location),
            params: {
              location: {
                name: "屋外育成棚",
                code: "outdoor-shelf",
                environment: "outdoor"
              }
            },
            headers: admin_headers

      expect(response).to redirect_to(admin_location_path(location))
      expect(location.reload).to have_attributes(
        name: "屋外育成棚",
        code: "outdoor-shelf",
        environment: "outdoor"
      )
    end
  end

  describe "DELETE /admin/locations/:id" do
    it "関連データがなければ削除する" do
      location = Location.create!(name: "削除対象", code: "delete-target", environment: "indoor")

      expect {
        delete admin_location_path(location), headers: admin_headers
      }.to change(Location, :count).by(-1)

      expect(response).to redirect_to(admin_locations_path)
    end

    it "Groupから参照されている場所は削除しない" do
      location = Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")
      StartProduction.call(
        plant_id: plant.id,
        propagation_method: "seed",
        started_on: Date.new(2026, 8, 14),
        initial_quantity: 5,
        location_id: location.id,
        growing_method: "soil"
      )

      expect {
        delete admin_location_path(location), headers: admin_headers
      }.not_to change(Location, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "Stockから参照されている場所は削除しない" do
      location = Location.create!(name: "販売棚", code: "sales-shelf", environment: "outdoor")
      Stock.register_direct!(
        plant_id: plant.id,
        location_id: location.id,
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 14)
      )

      expect {
        delete admin_location_path(location), headers: admin_headers
      }.not_to change(Location, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
