require "rails_helper"

RSpec.describe "Admin::StockObservations", type: :request do

  let(:create_plant) do
    Plant.create!(
      name: "テストプラント",
      code: "test",
      prefix: "TST"
    )
  end
  let(:create_location) do
    Location.create!(
      name: "テストロケーション",
      code: "test",
      prefix: "TST"
    )
  end
  let(:create_stock) do
    Stocks::Creator.call(
      plant_id: create_plant.id,
      location_id: create_location.id,
      growing_method: "pot",
      propagation_method: "seed"
    )
  end
  let(:create_other_stock) do
    Stocks::Creator.call(
      plant_id: create_plant.id,
      location_id: create_location.id,
      growing_method: "pot",
      propagation_method: "seed"
    )
  end
  let(:create_stock_observation) do
    StockObservation.create!(
      stock_id: create_stock.id,
      height_cm: 5.0,
      memo: "test",
      recoded_at: Time.now
    )
  end
  let(:create_stock_observation2) do
    StockObservation.create!(
      stock_id: create_other_stock.id,
      height_cm: 5.0,
      memo: "test",
      recoded_at: Time.now
    )
  end

  let(:valid_params) do
    {
      stock_action_log: {
        stock_id: create_stock.id,
        height_cm: 5.0,
        memo: "test",
        recoded_at: Time.now
      }
    }
  end
  let(:invalid_params) do
    {
      stock_action_log: {
        stock_id: nil,
        height_cm: 5.0,
        memo: "test",
        recoded_at: Time.now
      }
    }
  end

  # index
  describe "GET /admin/stock_observations" do
    it "保存済みのStockObservationが一覧に表示される" do
      stock_observation = create_stock_observation
      stock_observation2 = create_stock_observation
      get admin_stock_observations_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # show
  describe "GET /admin/stock_observations/:id" do
    it "StockObservation詳細が表示される" do
      stock_observation = create_parent_stock_observation
      get admin_stock_observation_path(stock_observation), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # new
  describe "GET /admin/stock_observations/new" do
    it "新規StockObservation作成画面が表示される" do
      get new_admin_stock_observation_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # create
  describe "POST /admin/stock_observations" do
    context "パラメータが正常な場合" do
      it "StockObservationを作成できる" do

        expect {
          post admin_stock_observations_path, params: valid_params, headers: admin_headers
        }.to change(StockObservation, :count).by(1)

        created_stock_observation = StockObservation.last

        # 作成値を検証
        expect(created_stock_observation.action_type).to eq("seed_sown")
        expect(created_stock_observation.memo).to eq("test")

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_stock_observation_path(created_stock_observation))

        expect(flash[:notice]).to eq("作成しました")
      end
    end

    context "パラメータが不正な場合" do
      it "StockObservationを作成できない" do
        expect {
          post admin_stock_observations_path, params: invalid_params, headers: admin_headers
        }.not_to change(StockObservation, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end
  end

  # edit
  describe "GET /admin/stock_observations/:id/edit" do
    it "StockObservation編集画面が表示される" do
      stock_observation = create_stock_observation
      get edit_admin_stock_observation_path(stock_observation), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # update
  describe "PATCH /admin/stock_observations/:id" do
    context "パラメータが正常な場合" do
      it "StockObservationを更新できる" do
        stock_observation = create_stock_observation
        params = {
          stock_observation: {action_type: "moved"}
        }
        patch admin_stock_observation_path(stock_observation, params), headers: admin_headers
        expect(stock_observation.reload.action_type).to eq("moved")
        expect(response).to redirect_to(admin_stock_observation_path(stock_observation))
        expect(flash[:notice]).to include("更新しました")
      end
      it "StockObservationに更新がない" do
        stock_observation = create_stock_observation
        patch admin_stock_observation_path(stock_observation, valid_params), headers: admin_headers
        expect(stock_observation.reload.growing_method).to eq("seed_down")
        expect(response).to redirect_to(admin_stock_observation_path(stock_observation))
        expect(flash[:notice]).to include("変更はありませんでした")
      end
    end
    context "パラメータが不正な場合" do
      it "StockObservationを更新できない" do
        stock_observation = create_stock_observation
        patch admin_stock_observation_path(stock_observation, invalid_params), headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/stock_observations/:id" do
    it "削除できる" do
      stock_observation = create_stock_observation
      delete admin_stock_observation_path(stock_observation), headers: admin_headers
      expect(response).to redirect_to(admin_stock_observations_path)
      expect(flash[:notice]).to eq("削除しました")
    end
  end
end
