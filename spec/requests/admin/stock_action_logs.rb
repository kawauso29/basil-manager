require "rails_helper"

RSpec.describe "Admin::StockActionLogs", type: :request do

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
  let(:create_stock_action_log) do
    StockActionLog.create!(
      stock_id: create_stock.id,
      action_type: "seed_sown",
      memo: "test",
      recoded_at: Time.now
    )
  end
  let(:create_stock_action_log2) do
    StockActionLog.create!(
      stock_id: create_other_stock.id,
      action_type: "seed_sown",
      memo: "test",
      recoded_at: Time.now
    )
  end

  let(:valid_params) do
    {
      stock_action_log: {
        stock_id: create_stock.id,
        action_type: "seed_sown",
        memo: "test",
        recoded_at: Time.now
      }
    }
  end
  let(:invalid_params) do
    {
      stock_action_log: {
        stock_id: nil,
        action_type: "seed_sown",
        memo: "test",
        recoded_at: Time.now
      }
    }
  end

  # index
  describe "GET /admin/stock_action_logs" do
    it "保存済みのStockActionLogが一覧に表示される" do
      stock_action_log = create_stock_action_log
      stock_action_log2 = create_stock_action_log
      get admin_stock_action_logs_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # show
  describe "GET /admin/stock_action_logs/:id" do
    it "StockActionLog詳細が表示される" do
      stock_action_log = create_parent_stock_action_log
      get admin_stock_action_log_path(stock_action_log), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # new
  describe "GET /admin/stock_action_logs/new" do
    it "新規StockActionLog作成画面が表示される" do
      get new_admin_stock_action_log_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # create
  describe "POST /admin/stock_action_logs" do
    context "パラメータが正常な場合" do
      it "StockActionLogを作成できる" do

        expect {
          post admin_stock_action_logs_path, params: valid_params, headers: admin_headers
        }.to change(StockActionLog, :count).by(1)

        created_stock_action_log = StockActionLog.last

        # 作成値を検証
        expect(created_stock_action_log.action_type).to eq("seed_sown")
        expect(created_stock_action_log.memo).to eq("test")

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_stock_action_log_path(created_stock_action_log))

        expect(flash[:notice]).to eq("作成しました")
      end
    end

    context "パラメータが不正な場合" do
      it "StockActionLogを作成できない" do
        expect {
          post admin_stock_action_logs_path, params: invalid_params, headers: admin_headers
        }.not_to change(StockActionLog, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end
  end

  # edit
  describe "GET /admin/stock_action_logs/:id/edit" do
    it "StockActionLog編集画面が表示される" do
      stock_action_log = create_stock_action_log
      get edit_admin_stock_action_log_path(stock_action_log), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # update
  describe "PATCH /admin/stock_action_logs/:id" do
    context "パラメータが正常な場合" do
      it "StockActionLogを更新できる" do
        stock_action_log = create_stock_action_log
        params = {
          stock_action_log: {action_type: "moved"}
        }
        patch admin_stock_action_log_path(stock_action_log, params), headers: admin_headers
        expect(stock_action_log.reload.action_type).to eq("moved")
        expect(response).to redirect_to(admin_stock_action_log_path(stock_action_log))
        expect(flash[:notice]).to include("更新しました")
      end
      it "StockActionLogに更新がない" do
        stock_action_log = create_stock_action_log
        patch admin_stock_action_log_path(stock_action_log, valid_params), headers: admin_headers
        expect(stock_action_log.reload.growing_method).to eq("seed_down")
        expect(response).to redirect_to(admin_stock_action_log_path(stock_action_log))
        expect(flash[:notice]).to include("変更はありませんでした")
      end
    end
    context "パラメータが不正な場合" do
      it "StockActionLogを更新できない" do
        stock_action_log = create_stock_action_log
        patch admin_stock_action_log_path(stock_action_log, invalid_params), headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/stock_action_logs/:id" do
    it "削除できる" do
      stock_action_log = create_stock_action_log
      delete admin_stock_action_log_path(stock_action_log), headers: admin_headers
      expect(response).to redirect_to(admin_stock_action_logs_path)
      expect(flash[:notice]).to eq("削除しました")
    end
  end
end
