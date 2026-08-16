require "rails_helper"

RSpec.describe "Admin::ProductionLots", type: :request do
  let!(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let!(:location) do
    Location.create!(name: "育苗棚", code: "nursery-shelf", environment: "indoor")
  end

  def start_production(overrides = {})
    StartProduction.call(
      **{
        plant_id: plant.id,
        propagation_method: "cutting",
        started_on: Date.new(2026, 8, 14),
        initial_quantity: 10,
        location_id: location.id,
        growing_method: "water",
        container_type: "コップ",
        memo: "水差し開始"
      }.merge(overrides)
    )
  end

  describe "GET /admin/production_lots" do
    it "生産ロットを一覧表示する" do
      production_lot = start_production

      get admin_production_lots_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("LOT-#{production_lot.id}", "バジル", "10株")
    end
  end

  describe "GET /admin/production_lots/:id" do
    it "ロット、苗グループ、鉢上げ後の株を表示する" do
      production_lot = start_production
      nursery_group = production_lot.nursery_groups.first
      AdvanceNurseryGroup.call(
        nursery_group: nursery_group,
        quantity: nursery_group.quantity,
        recorded_on: Date.new(2026, 8, 15)
      )
      AdvanceNurseryGroup.call(
        nursery_group: nursery_group,
        quantity: nursery_group.quantity,
        recorded_on: Date.new(2026, 8, 16)
      )
      stock = PotUpNurseryGroup.call(
        nursery_group: nursery_group,
        quantity: 1,
        location_id: location.id,
        potted_on: Date.new(2026, 8, 17)
      ).first

      get admin_production_lot_path(production_lot), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "LOT-#{production_lot.id}",
        "NG-#{nursery_group.id}",
        "ST-#{stock.id}",
        "水差し開始"
      )
    end
  end

  describe "GET /admin/production_lots/new" do
    it "生産開始フォームを表示する" do
      get new_admin_production_lot_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'name="production[plant_id]"',
        'name="production[initial_quantity]"',
        'name="production[growing_method]"'
      )
      expect(response.body).not_to include("9cm")
    end
  end

  describe "POST /admin/production_lots" do
    let(:valid_params) do
      {
        production: {
          plant_id: plant.id,
          propagation_method: "cutting",
          started_on: "2026-08-14",
          initial_quantity: "10",
          location_id: location.id,
          growing_method: "water",
          container_type: "コップ",
          memo: "水差し開始"
        }
      }
    end

    it "Lotと最初のGroupを同時に作成する" do
      expect {
        post admin_production_lots_path, params: valid_params, headers: admin_headers
      }.to change(ProductionLot, :count).by(1)
       .and change(NurseryGroup, :count).by(1)

      production_lot = ProductionLot.last
      nursery_group = production_lot.nursery_groups.first
      expect(response).to redirect_to(admin_production_lot_path(production_lot))
      expect(production_lot).to have_attributes(
        plant_id: plant.id,
        propagation_method: "cutting",
        initial_quantity: 10
      )
      expect(nursery_group).to have_attributes(
        stage: "rooting_wait",
        growing_method: "water",
        quantity: 10,
        location_id: location.id
      )
    end

    it "入力が不正ならどちらも作成しない" do
      invalid_params = valid_params.deep_merge(production: { initial_quantity: "0" })

      expect {
        post admin_production_lots_path, params: invalid_params, headers: admin_headers
      }.not_to change(ProductionLot, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(NurseryGroup.count).to eq(0)
    end
  end

  it "物理削除ルートを持たない" do
    production_lot = start_production

    expect {
      Rails.application.routes.recognize_path(
        admin_production_lot_path(production_lot),
        method: :delete
      )
    }.to raise_error(ActionController::RoutingError)
  end
end
