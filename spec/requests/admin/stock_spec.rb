require "rails_helper"

RSpec.describe "Admin::Stocks", type: :request do
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
  let(:create_parent_stock) do
    parent_stock = create_stock
    child_stock = create_other_stock
    child_stock.update!(parent_stock_id: parent_stock.id)
    parent_stock
  end
  let(:create_child_stock) do
    parent_stock = create_stock
    child_stock = create_other_stock
    child_stock.update!(parent_stock_id: parent_stock.id)
    child_stock
  end
  let(:valid_params) do
    {
      stock: {
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        label: "テスト株"
      }
    }
  end
  let(:invalid_params) do
    {
      stock: {
        plant_id: nil,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        label: "テスト株"
      }
    }
  end

  # index
  describe "GET /admin/stocks" do
    it "保存済みのStockが一覧に表示される" do
      stock = create_stock
      stock.update!(memo: "遮光ラックの上段")
      create_stock
      get admin_stocks_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("テスト株")
      expect(response.body).to include("遮光ラックの上段")
      expect(response.body).to include(stock.created_at.strftime("%Y/%m/%d"))
    end
  end

  # show
  describe "GET /admin/stocks/:id" do
    context "親株である" do
      it "Stock詳細が表示される" do
        stock = create_parent_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.parent?).to eq(true)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("テスト株")
      end
    end
    context "親株ではない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.parent?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株である" do
      it "Stock詳細が表示される" do
        stock = create_child_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.child?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株ではない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.child?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "親株を持つ" do
      it "Stock詳細が表示される" do
        stock = create_child_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_parent?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "親株を持たない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_parent?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株を持つ" do
      it "Stock詳細が表示される" do
        stock = create_parent_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_children?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株を持たない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_children?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "作業ログと観察ログを持つ" do
      it "ログを含むStock詳細が表示される" do
        stock = create_stock
        stock.stock_action_logs.create!(
          action_type: :watered,
          memo: "作業ログ",
          recorded_at: Time.zone.local(2026, 7, 2, 9)
        )
        stock.stock_observations.create!(
          height_cm: 10,
          memo: "観察ログ",
          recorded_at: Time.zone.local(2026, 7, 1, 8)
        )

        get admin_stock_path(stock), headers: admin_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("作業ログ")
        expect(response.body).to include("観察ログ")
      end
    end
  end

  # new
  describe "GET /admin/stocks/new" do
    it "新規Stock作成画面が表示される" do
      get new_admin_stock_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="stock[image]"')
    end
  end

  # create
  describe "POST /admin/stocks" do
    context "パラメータが正常な場合" do
      it "Stockを作成できる" do
        params = valid_params.deep_merge(
          stock: { image: fixture_file_upload(Rails.root.join("public/icon.png"), "image/png") }
        )

        expect {
          post admin_stocks_path, params: params, headers: admin_headers
        }.to change(Stock, :count).by(1)

        created_stock = Stock.last

        # 作成値を検証
        expect(created_stock.plant.name).to eq("テストプラント")
        expect(created_stock.location.name).to eq("テストロケーション")
        expect(created_stock.growing_method).to eq("pot")
        expect(created_stock.propagation_method).to eq("seed")
        expect(created_stock.label).to eq("テスト株")
        expect(created_stock.image).to be_attached

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_stock_path(created_stock))

        expect(flash[:notice]).to eq("作成しました")
      end

      it "増殖方法が未設定でもStockを作成できる" do
        params = {
          stock: {
            plant_id: create_plant.id,
            location_id: create_location.id,
            growing_method: "pot",
            propagation_method: ""
          }
        }

        expect {
          post admin_stocks_path, params: params, headers: admin_headers
        }.to change(Stock, :count).by(1)

        expect(Stock.last.propagation_method).to be_nil
      end

      it "数量とメモを指定してStockを作成できる" do
        params = {
          stock: {
            plant_id: create_plant.id,
            location_id: create_location.id,
            growing_method: "pot",
            propagation_method: "cutting_soil",
            quantity: 20,
            memo: "摘芯で作った挿し穂"
          }
        }

        post admin_stocks_path, params: params, headers: admin_headers

        created_stock = Stock.last
        expect(created_stock.quantity).to eq(20)
        expect(created_stock.memo).to eq("摘芯で作った挿し穂")
      end
    end

    context "パラメータが不正な場合" do
      it "Stockを作成できない" do
        expect {
          post admin_stocks_path, params: invalid_params, headers: admin_headers
        }.not_to change(Stock, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end
  end

  # edit
  describe "GET /admin/stocks/:id/edit" do
    it "Stock編集画面が表示される" do
      stock = create_stock
      get edit_admin_stock_path(stock), headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("テスト株")
    end
  end

  # update
  describe "PATCH /admin/stocks/:id" do
    context "パラメータが正常な場合" do
      it "Stockを更新できる" do
        stock = create_stock
        params = {
          stock: { growing_method: "water" }
        }
        patch admin_stock_path(stock, params), headers: admin_headers
        expect(stock.reload.growing_method).to eq("water")
        expect(response).to redirect_to(admin_stock_path(stock))
        expect(flash[:notice]).to include("更新しました")
      end
      it "Stockに更新がない" do
        stock = create_stock
        patch admin_stock_path(stock, valid_params), headers: admin_headers
        expect(stock.reload.growing_method).to eq("pot")
        expect(response).to redirect_to(admin_stock_path(stock))
        expect(flash[:notice]).to include("変更はありませんでした")
      end

      it "Stockのメモを更新できる" do
        stock = create_stock

        patch admin_stock_path(stock),
              params: { stock: { memo: "南側の青いトレー" } },
              headers: admin_headers

        expect(stock.reload.memo).to eq("南側の青いトレー")
      end

      it "管理場所を変更して構造化された作業ログを作成する" do
        stock = create_stock
        destination = Location.create!(name: "移動先", code: "dst", prefix: "DST")

        expect {
          patch admin_stock_path(stock),
                params: { stock: { location_id: destination.id, history_memo: "遮光ラックへ移動" } },
                headers: admin_headers
        }.to change(StockActionLog, :count).by(1)

        action_log = stock.stock_action_logs.last
        expect(stock.reload.location).to eq(destination)
        expect(action_log).to have_attributes(
          action_type: "moved",
          from_location_id: create_location.id,
          to_location_id: destination.id,
          memo: "遮光ラックへ移動"
        )
      end

      it "管理状態を変更して構造化された作業ログを作成する" do
        stock = create_stock

        expect {
          patch admin_stock_path(stock),
                params: { stock: { status: "rooting", history_memo: "発根を確認" } },
                headers: admin_headers
        }.to change(StockActionLog, :count).by(1)

        action_log = stock.stock_action_logs.last
        expect(stock.reload.status).to eq("rooting")
        expect(action_log).to have_attributes(
          action_type: "status_changed",
          status_before: "starting",
          status_after: "rooting",
          memo: "発根を確認"
        )
      end

      it "通常の更新では数量を変更できない" do
        stock = create_stock

        patch admin_stock_path(stock),
              params: { stock: { quantity: 20 } },
              headers: admin_headers

        expect(stock.reload.quantity).to eq(1)
      end
    end
    context "パラメータが不正な場合" do
      it "Stockを更新できない" do
        stock = create_stock
        patch admin_stock_path(stock, invalid_params), headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  describe "PATCH /admin/stocks/:id/change_quantity" do
    context "数量が正常な場合" do
      it "数量を変更して作業ログを作成する" do
        stock = create_stock

        expect {
          patch change_quantity_admin_stock_path(stock),
                params: {
                  stock_quantity: {
                    quantity: 20,
                    memo: "摘芯で作った挿し穂"
                  }
                },
                headers: admin_headers
        }.to change(StockActionLog, :count).by(1)

        expect(stock.reload.quantity).to eq(20)

        action_log = stock.stock_action_logs.last
        expect(action_log.action_type).to eq("quantity_changed")
        expect(action_log.quantity_before).to eq(1)
        expect(action_log.quantity_after).to eq(20)
        expect(action_log.memo).to eq("1株 → 20株（摘芯で作った挿し穂）")
        expect(action_log.recorded_at).to be_present
        expect(response).to redirect_to(admin_stock_path(stock))
      end
    end

    context "数量が不正な場合" do
      it "数量を変更せず作業ログも作成しない" do
        stock = create_stock

        expect {
          patch change_quantity_admin_stock_path(stock),
                params: { stock_quantity: { quantity: 0 } },
                headers: admin_headers
        }.not_to change(StockActionLog, :count)

        expect(stock.reload.quantity).to eq(1)
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash.now[:alert]).to include("数量変更に失敗しました")
      end
    end

    context "数量が変更前と同じ場合" do
      it "作業ログを作成しない" do
        stock = create_stock

        expect {
          patch change_quantity_admin_stock_path(stock),
                params: { stock_quantity: { quantity: 1 } },
                headers: admin_headers
        }.not_to change(StockActionLog, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/stocks/:id/edit_quantity" do
    it "数量変更画面を表示する" do
      stock = create_stock

      get edit_quantity_admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("数量を変更")
      expect(response.body).to include(stock.display_name)
    end
  end

  # destroy
  describe "DELETE /admin/stocks/:id" do
    context "子を持つ場合" do
      it "親Stockを削除できない" do
        stock = create_parent_stock
        delete admin_stock_path(stock), headers: admin_headers
        expect(flash.now[:alert]).to include("削除に失敗しました")
      end
    end
    context "子のStockを持たない場合" do
      it "親でも子でもないStockを削除できる" do
        stock = create_stock
        delete admin_stock_path(stock), headers: admin_headers
        expect(response).to redirect_to(admin_stocks_path)
        expect(flash[:notice]).to eq("削除しました")
      end
      it "子であるStockを削除できる" do
        stock = create_child_stock
        delete admin_stock_path(stock), headers: admin_headers
        expect(response).to redirect_to(admin_stocks_path)
        expect(flash[:notice]).to eq("削除しました")
      end
    end
  end
end
