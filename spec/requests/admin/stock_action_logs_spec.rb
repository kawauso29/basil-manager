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
      propagation_method: "seed",
      label: "テスト株"
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
      recorded_at: nil
    )
  end
  let(:create_stock_action_log2) do
    StockActionLog.create!(
      stock_id: create_other_stock.id,
      action_type: "seed_sown",
      memo: "test",
      recorded_at: nil
    )
  end

  describe "GET /admin/stock_action_logs/bulk_new" do
    it "環境とロケーションで選択できる育成中の株を表示する" do
      indoor_stock = create_stock
      outdoor_location = Location.create!(
        name: "屋外テストロケーション",
        code: "outdoor-test",
        prefix: "OUT",
        environment: "outdoor"
      )
      outdoor_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: outdoor_location.id,
        growing_method: "pot",
        label: "屋外テスト株"
      )
      completed_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: outdoor_location.id,
        growing_method: "pot",
        label: "育成完了株"
      )
      completed_stock.update!(
        completion_reason: "cultivation_ended",
        completed_at: Time.current
      )

      get bulk_new_admin_stock_action_logs_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("アクションを一括記録")
      expect(response.body).to include("屋内", "屋外")
      expect(response.body).to include(create_location.name, outdoor_location.name)
      expect(response.body).to include(indoor_stock.display_name, outdoor_stock.display_name)
      expect(response.body).not_to include(completed_stock.display_name)
      expect(response.body).to include("水やり")
    end
  end

  describe "POST /admin/stock_action_logs/bulk_create" do
    let(:outdoor_location) do
      Location.create!(
        name: "屋外テストロケーション",
        code: "outdoor-test",
        prefix: "OUT",
        environment: "outdoor"
      )
    end
    let(:outdoor_stock) do
      Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: outdoor_location.id,
        growing_method: "pot",
        label: "屋外テスト株"
      )
    end

    it "選択した複数ロケーションの株ごとに同じアクションを記録する" do
      recorded_at = Time.zone.parse("2026-07-28 08:30")
      other_outdoor_location = Location.create!(
        name: "屋外テストロケーション2",
        code: "outdoor-test-2",
        prefix: "OT2",
        environment: "outdoor"
      )
      other_outdoor_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: other_outdoor_location.id,
        growing_method: "pot",
        label: "屋外テスト株2"
      )
      params = {
        stock_action_log: {
          environment: "outdoor",
          location_ids: [ outdoor_location.id, other_outdoor_location.id ],
          stock_ids: [ outdoor_stock.id, other_outdoor_stock.id ],
          action_type: "fertilized",
          memo: "液肥",
          recorded_at: recorded_at
        }
      }

      expect {
        post bulk_create_admin_stock_action_logs_path, params: params, headers: admin_headers
      }.to change(StockActionLog, :count).by(2)

      created_logs = StockActionLog.order(:id).last(2)
      expect(created_logs.map(&:stock_id)).to contain_exactly(outdoor_stock.id, other_outdoor_stock.id)
      expect(created_logs.map(&:action_type)).to eq(%w[ fertilized fertilized ])
      expect(created_logs.map(&:memo)).to eq(%w[ 液肥 液肥 ])
      expect(created_logs.map(&:recorded_at)).to all(eq(recorded_at))
      expect(response).to redirect_to(admin_stock_action_logs_path)
      expect(flash[:notice]).to eq("作成しました")
    end

    it "株が未選択の場合は作成しない" do
      params = {
        stock_action_log: {
          environment: "outdoor",
          action_type: "watered",
          recorded_at: Time.current
        }
      }

      expect {
        post bulk_create_admin_stock_action_logs_path, params: params, headers: admin_headers
      }.not_to change(StockActionLog, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash.now[:alert]).to eq("対象の株を選択してください")
    end

    it "専用操作で記録するアクション種別は一括作成しない" do
      params = {
        stock_action_log: {
          environment: "outdoor",
          stock_ids: [ outdoor_stock.id ],
          action_type: "moved",
          recorded_at: Time.current
        }
      }

      expect {
        post bulk_create_admin_stock_action_logs_path, params: params, headers: admin_headers
      }.not_to change(StockActionLog, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash.now[:alert]).to eq("一括記録できるアクション種別を選択してください")
    end

    it "育成完了済みの株が含まれる場合は全件を作成しない" do
      completed_stock = outdoor_stock
      active_outdoor_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: outdoor_location.id,
        growing_method: "pot",
        label: "育成中の屋外テスト株"
      )
      completed_stock.update!(
        completion_reason: "cultivation_ended",
        completed_at: Time.current
      )
      params = {
        stock_action_log: {
          environment: "outdoor",
          stock_ids: [ active_outdoor_stock.id, completed_stock.id ],
          action_type: "watered",
          recorded_at: Time.current
        }
      }

      expect {
        post bulk_create_admin_stock_action_logs_path, params: params, headers: admin_headers
      }.not_to change(StockActionLog, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash.now[:alert]).to eq("選択した条件に一致する育成中の株だけを選択してください")
    end

    it "選択した条件に一致しない株が含まれる場合は全件を作成しない" do
      params = {
        stock_action_log: {
          environment: "outdoor",
          location_ids: [ outdoor_location.id ],
          stock_ids: [ create_stock.id, outdoor_stock.id ],
          action_type: "watered",
          recorded_at: Time.current
        }
      }

      expect {
        post bulk_create_admin_stock_action_logs_path, params: params, headers: admin_headers
      }.not_to change(StockActionLog, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash.now[:alert]).to eq("選択した条件に一致する育成中の株だけを選択してください")
    end

    it "選択した環境と異なるロケーションが含まれる場合は作成しない" do
      params = {
        stock_action_log: {
          environment: "outdoor",
          location_ids: [ outdoor_location.id, create_location.id ],
          stock_ids: [ outdoor_stock.id ],
          action_type: "watered",
          recorded_at: Time.current
        }
      }

      expect {
        post bulk_create_admin_stock_action_logs_path, params: params, headers: admin_headers
      }.not_to change(StockActionLog, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash.now[:alert]).to eq("選択した環境のロケーションだけを指定してください")
    end
  end

  let(:valid_params) do
    {
      stock_action_log: {
        stock_id: create_stock.id,
        action_type: "seed_sown",
        memo: "test",
        recorded_at: nil
      }
    }
  end
  let(:invalid_params) do
    {
      stock_action_log: {
        stock_id: create_stock.id,
        action_type: "",
        memo: "test",
        recorded_at: nil
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
      expect(response.body).to include("テスト株")
    end
  end

  # show
  describe "GET /admin/stock_action_logs/:id" do
    it "StockActionLog詳細が表示される" do
      stock_action_log = create_stock_action_log
      get admin_stock_action_log_path(stock_action_log), headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("テスト株")
    end
  end

  # new
  describe "GET /admin/stock_action_logs/new" do
    it "新規StockActionLog作成画面が表示される" do
      create_stock
      get new_admin_stock_action_log_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("テスト株")
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
        expect(response).to redirect_to(admin_stock_action_logs_path)

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

      it "構造化履歴の作業種別は通常の作業ログとして作成できない" do
        params = {
          stock_action_log: {
            stock_id: create_stock.id,
            action_type: "moved"
          }
        }

        expect {
          post admin_stock_action_logs_path, params: params, headers: admin_headers
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
      expect(response.body).to include("テスト株")
    end
  end

  # update
  describe "PATCH /admin/stock_action_logs/:id" do
    context "パラメータが正常な場合" do
      it "StockActionLogを更新できる" do
        stock_action_log = create_stock_action_log
        params = {
          stock_action_log: { action_type: "watered" }
        }
        patch admin_stock_action_log_path(stock_action_log, params), headers: admin_headers
        expect(stock_action_log.reload.action_type).to eq("watered")
        expect(response).to redirect_to(admin_stock_action_log_path(stock_action_log))
        expect(flash[:notice]).to include("更新しました")
      end
      it "StockActionLogに更新がない" do
        stock_action_log = create_stock_action_log
        patch admin_stock_action_log_path(stock_action_log, valid_params), headers: admin_headers
        expect(stock_action_log.reload.action_type).to eq("seed_sown")
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
