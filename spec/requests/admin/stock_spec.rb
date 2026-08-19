require "rails_helper"

RSpec.describe "Admin::Stocks", type: :request do
  let!(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let!(:location) do
    Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")
  end
  let!(:destination) do
    Location.create!(name: "販売棚", code: "sales-shelf", environment: "outdoor")
  end

  def create_stock(overrides = {})
    Stock.register_direct!(
      **{
        plant_id: plant.id,
        location_id: location.id,
        stage: "acclimating",
        stage_started_on: Date.new(2026, 8, 14),
        potted_on: nil,
        memo: "購入株"
      }.merge(overrides)
    )
  end

  describe "GET /admin/stocks" do
    it "管理中と完了済みのStockをどちらも一覧表示する" do
      active_stock = create_stock
      completed_stock = create_stock(memo: "管理終了株")
      completed_stock.complete!(
        reason: "cultivation_ended",
        at: Time.zone.local(2026, 8, 15, 10)
      )

      get admin_stocks_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ST-#{active_stock.id}", "ST-#{completed_stock.id}", "管理終了株")
      # 管理画面レイアウト（ヘッダー）が付くこと
      expect(response.body).to include("primary-nav")
    end

    it "工程、場所、植物、管理状態で絞り込む" do
      target = create_stock(stage: "growing", location_id: destination.id, memo: "対象")
      create_stock(memo: "対象外")

      get admin_stocks_path,
          params: {
            environment: "outdoor",
            location_id: destination.id,
            plant_id: plant.id,
            stage: "growing",
            completion: "active"
          },
          headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ST-#{target.id}", "対象")
      expect(response.body).not_to include("対象外")
    end

    it "販売可能フィルタでは完了済みStockを除外する" do
      active_ready = create_stock(stage: "growing", memo: "販売中")
      active_ready.mark_sale_ready!(on: Date.new(2026, 8, 15))
      completed_ready = create_stock(stage: "growing", memo: "販売終了")
      completed_ready.mark_sale_ready!(on: Date.new(2026, 8, 15))
      completed_ready.complete!(reason: "transferred", at: Time.zone.local(2026, 8, 16, 10))

      get admin_stocks_path, params: { sale_ready: "ready" }, headers: admin_headers

      expect(response.body).to include("ST-#{active_ready.id}", "販売中")
      expect(response.body).not_to include("ST-#{completed_ready.id}")
      expect(response.body).not_to include("販売終了")
    end
  end

  describe "GET /admin/stocks/new" do
    it "直接登録に必要な現在値のフォームを表示する" do
      get new_admin_stock_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'name="stock[plant_id]"',
        'name="stock[location_id]"',
        'name="stock[stage]"',
        'name="stock[stage_started_on]"',
        'name="stock[potted_on]"'
      )
      expect(response.body).not_to include("9cm", "個体コード", "ラベル")
    end
  end

  describe "GET /admin/stocks/:id" do
    it "業務現在値、出自、最新草丈を表示する" do
      production_lot = StartProduction.call(
        plant_id: plant.id,
        propagation_method: "cutting",
        started_on: Date.new(2026, 8, 10),
        initial_quantity: 1,
        location_id: location.id,
        growing_method: "water"
      )
      nursery_group = production_lot.nursery_groups.first
      2.times do |index|
        AdvanceNurseryGroup.call(
          nursery_group: nursery_group,
          quantity: nursery_group.quantity,
          recorded_on: Date.new(2026, 8, 11 + index)
        )
      end
      stock = PotUpNurseryGroup.call(
        nursery_group: nursery_group,
        quantity: 1,
        location_id: destination.id,
        potted_on: Date.new(2026, 8, 13)
      ).first
      stock.stock_observations.create!(
        height_cm: 8,
        memo: "古い記録",
        recorded_at: Time.zone.local(2026, 8, 14, 9)
      )
      stock.stock_observations.create!(
        height_cm: 12.5,
        memo: "最新記録",
        recorded_at: Time.zone.local(2026, 8, 15, 9)
      )

      get admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "ST-#{stock.id}",
        "LOT-#{production_lot.id}",
        "NG-#{nursery_group.id}",
        "12.5 cm",
        "2026/08/13"
      )
      expect(response.body).not_to include("作業を記録", "削除", "9cm")
    end

    it "完了後も販売可能日と完了内容を表示する" do
      stock = create_stock(stage: "growing", potted_on: Date.new(2026, 8, 10))
      stock.mark_sale_ready!(on: Date.new(2026, 8, 14))
      stock.complete!(reason: "transferred", at: Time.zone.local(2026, 8, 15, 11, 30))

      get admin_stock_path(stock), headers: admin_headers

      expect(response.body).to include("2026/08/14", "2026/08/15 11:30", "譲渡")
      expect(response.body).not_to include("販売可能を解除", "管理を完了")
    end
  end

  describe "POST /admin/stocks" do
    let(:valid_params) do
      {
        stock: {
          plant_id: plant.id,
          location_id: location.id,
          stage: "growing",
          stage_started_on: "2026-08-14",
          potted_on: "",
          memo: "購入した株"
        }
      }
    end

    it "LotなしのStockを直接登録する" do
      expect {
        post admin_stocks_path, params: valid_params, headers: admin_headers
      }.to change(Stock, :count).by(1)

      stock = Stock.last
      expect(response).to redirect_to(admin_stock_path(stock))
      expect(stock).to have_attributes(
        plant_id: plant.id,
        location_id: location.id,
        source_nursery_group_id: nil,
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 14),
        potted_on: nil,
        memo: "購入した株"
      )
    end

    it "必須項目がなければ登録しない" do
      invalid_params = valid_params.deep_merge(stock: { stage_started_on: "" })

      expect {
        post admin_stocks_path, params: invalid_params, headers: admin_headers
      }.not_to change(Stock, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/stocks/:id" do
    it "場所、鉢上げ日、メモだけを通常編集する" do
      stock = create_stock

      patch admin_stock_path(stock),
            params: {
              stock: {
                location_id: destination.id,
                potted_on: "2026-08-12",
                memo: "販売棚へ移動",
                plant_id: -1,
                stage: "growing"
              }
            },
            headers: admin_headers

      expect(response).to redirect_to(admin_stock_path(stock))
      expect(stock.reload).to have_attributes(
        plant_id: plant.id,
        location_id: destination.id,
        stage: "acclimating",
        potted_on: Date.new(2026, 8, 12),
        memo: "販売棚へ移動"
      )
    end
  end

  describe "GET /admin/stocks/:id/edit" do
    it "場所、鉢上げ日、メモだけを編集するフォームを表示する" do
      stock = create_stock

      get edit_admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'name="stock[location_id]"',
        'name="stock[potted_on]"',
        'name="stock[memo]"'
      )
      expect(response.body).not_to include('name="stock[plant_id]"', 'name="stock[stage]"')
    end
  end

  describe "GET /admin/stocks/labels" do
    it "絞り込んだ株のQRラベルを印刷用レイアウトで並べる" do
      target = create_stock(stage: "growing")
      target.mark_sale_ready!(on: Date.new(2026, 8, 20))
      other = create_stock

      get labels_admin_stocks_path(sale_ready: "ready"), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.display_name)
      expect(response.body).not_to include(other.display_name)
      # QRはHTMLへ直接埋め込む。印刷時に未読み込みで欠けるのを避けるため
      expect(response.body).to include("data:image/png;base64,")
      # 管理画面のナビゲーションを紙に載せない
      expect(response.body).not_to include("primary-nav")
    end
  end

  describe "GET /admin/stocks/:id/qr" do
    it "公開ページのQRコードをPNGで返す" do
      stock = create_stock

      get qr_admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.body).to start_with("\x89PNG".b)
    end
  end

  describe "専用操作フォーム" do
    it "工程進行フォームを表示する" do
      stock = create_stock

      get advance_stage_admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ST-#{stock.id}", 'name="stock_stage[stage_started_on]"')
    end

    it "販売可能設定フォームを表示する" do
      stock = create_stock(stage: "growing")

      get sale_ready_admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ST-#{stock.id}", 'name="sale_ready[sale_ready_on]"')
    end

    it "管理完了フォームを表示する" do
      stock = create_stock(stage: "growing")

      get complete_admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "ST-#{stock.id}",
        'name="completion[completion_reason]"',
        'name="completion[completed_at]"'
      )
    end
  end

  describe "PATCH /admin/stocks/:id/advance_stage" do
    it "専用操作でacclimatingからgrowingへ進める" do
      stock = create_stock

      patch advance_stage_admin_stock_path(stock),
            params: { stock_stage: { stage_started_on: "2026-08-15" } },
            headers: admin_headers

      expect(response).to redirect_to(admin_stock_path(stock))
      expect(stock.reload).to have_attributes(
        stage: "growing",
        stage_started_on: Date.new(2026, 8, 15)
      )
    end
  end

  describe "販売可能の設定と解除" do
    it "専用操作で販売可能日を設定する" do
      stock = create_stock(stage: "growing")

      patch mark_sale_ready_admin_stock_path(stock),
            params: { sale_ready: { sale_ready_on: "2026-08-15" } },
            headers: admin_headers

      expect(response).to redirect_to(admin_stock_path(stock))
      expect(stock.reload.sale_ready_on).to eq(Date.new(2026, 8, 15))
    end

    it "専用操作で販売可能を解除する" do
      stock = create_stock(stage: "growing")
      stock.mark_sale_ready!(on: Date.new(2026, 8, 15))

      patch revoke_sale_ready_admin_stock_path(stock), headers: admin_headers

      expect(response).to redirect_to(admin_stock_path(stock))
      expect(stock.reload.sale_ready_on).to be_nil
    end
  end

  describe "PATCH /admin/stocks/:id/complete" do
    it "完了理由と日時を同時に保存する" do
      stock = create_stock(stage: "growing")

      patch complete_admin_stock_path(stock),
            params: {
              completion: {
                completion_reason: "dead",
                completed_at: "2026-08-15T10:30"
              }
            },
            headers: admin_headers

      expect(response).to redirect_to(admin_stock_path(stock))
      expect(stock.reload).to have_attributes(
        completion_reason: "dead",
        completed_at: Time.zone.local(2026, 8, 15, 10, 30)
      )
    end
  end

  it "Stockの物理削除ルートを持たない" do
    stock = create_stock

    expect {
      Rails.application.routes.recognize_path(admin_stock_path(stock), method: :delete)
    }.to raise_error(ActionController::RoutingError)
  end
end
