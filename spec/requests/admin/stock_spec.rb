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

  describe "共通アクション" do
    it "一覧と作成画面で共通のコレクション操作を表示する" do
      {
        admin_stocks_path => "株一覧",
        new_admin_stock_path => "株を作成"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="株の操作"]')
        expect(actions.text).to include("株を作成", "株一覧")
        expect(actions.at_css('[aria-current="page"]').text.strip).to eq(current_label)
      end
    end

    it "詳細・編集画面で共通のレコード操作を表示する" do
      stock = create_stock

      {
        admin_stock_path(stock) => "詳細",
        edit_admin_stock_path(stock) => "編集"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="株の操作"]')
        expect(actions.text).to include(
          "詳細",
          "作業を記録",
          "観察を記録",
          "編集",
          "株を作成",
          "株一覧"
        )
        expect(actions.at_css('input[value="削除"]')).to be_present
        expect(actions.at_css('[aria-current="page"]').text.strip).to eq(current_label)
      end
    end
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
      expect(response.body).to include(edit_admin_stock_path(stock))
    end

    it "環境とロケーションを組み合わせて絞り込む" do
      indoor_stock = create_stock
      indoor_stock.update!(label: "屋内の株")
      target_location = Location.create!(
        name: "対象の屋外ロケーション",
        code: "target-outdoor",
        prefix: "TGO",
        environment: "outdoor"
      )
      other_location = Location.create!(
        name: "別の屋外ロケーション",
        code: "other-outdoor",
        prefix: "OGO",
        environment: "outdoor"
      )
      target_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: target_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        label: "対象の株"
      )
      other_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: other_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        label: "別の屋外株"
      )

      get admin_stocks_path,
          params: { environment: "outdoor", location_id: target_location.id },
          headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target_stock.label)
      expect(response.body).not_to include(indoor_stock.label, other_stock.label)
    end

    it "植物と状態を組み合わせて絞り込む" do
      target_stock = create_stock
      target_stock.update!(label: "対象の株", status: "growing")
      other_plant = Plant.create!(
        name: "別のテストプラント",
        code: "other-test",
        prefix: "OTH"
      )
      other_plant_stock = Stocks::Creator.call(
        plant_id: other_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        label: "別の植物の株"
      )
      other_status_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        label: "別の状態の株"
      )
      other_status_stock.update!(status: "rooting")

      get admin_stocks_path,
          params: { plant_id: create_plant.id, status: "growing" },
          headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target_stock.label)
      expect(response.body).not_to include(other_plant_stock.label, other_status_stock.label)
    end

    it "一覧表示に必要な関連データを一括取得する" do
      stock = create_stock
      blob = ActiveStorage::Blob.create!(
        key: SecureRandom.hex(20),
        filename: "stock.png",
        content_type: "image/png",
        metadata: { identified: true },
        service_name: ActiveStorage::Blob.service.name,
        byte_size: 100,
        checksum: "test-checksum"
      )
      ActiveStorage::Attachment.create!(name: "image", record: stock, blob: blob)

      other_plant = Plant.create!(
        name: "別のテストプラント",
        code: "other-test",
        prefix: "OTH"
      )
      other_location = Location.create!(
        name: "別のテストロケーション",
        code: "other-test",
        prefix: "OTH"
      )
      Stocks::Creator.call(
        plant_id: other_plant.id,
        location_id: other_location.id,
        growing_method: "pot",
        propagation_method: "seed"
      )

      sql_queries = []
      subscriber = lambda do |_name, _started, _finished, _id, payload|
        next if payload[:cached] || payload[:name].in?(%w[ SCHEMA TRANSACTION ])

        sql_queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get admin_stocks_path, headers: admin_headers
      end

      table_query_counts = sql_queries.filter_map do |sql|
        sql[/FROM\s+"([a-z_]+)"/, 1]
      end.tally

      expect(response).to have_http_status(:ok)
      expect(table_query_counts.slice(
        "stocks",
        "plants",
        "locations",
        "active_storage_attachments",
        "active_storage_blobs"
      )).to eq(
        "stocks" => 1,
        "plants" => 2,
        "locations" => 2,
        "active_storage_attachments" => 1,
        "active_storage_blobs" => 1
      )
    end
  end

  # show
  describe "GET /admin/stocks/:id" do
    it "操作をヘッダーにまとめ、株カード内の詳細リンクを表示しない" do
      stock = create_stock

      get admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("作業を記録")
      expect(response.body).to include("観察を記録")
      expect(response.body).to include("編集")
      expect(response.body).to include("削除")
      document = Nokogiri::HTML(response.body)
      expect(document.css(".stock-card a").map { |link| link.text.strip }).not_to include("詳細")
    end

    it "ID順で前後のStock詳細へ移動できる" do
      stocks = 3.times.map do |index|
        Stocks::Creator.call(
          plant_id: create_plant.id,
          location_id: create_location.id,
          growing_method: "pot",
          propagation_method: "seed",
          label: "ナビゲーション用株#{index}"
        )
      end

      get admin_stock_path(stocks.second), headers: admin_headers

      document = Nokogiri::HTML(response.body)
      expect(document.at_css('a[rel="prev"]')["href"]).to eq(admin_stock_path(stocks.first))
      expect(document.at_css('a[rel="next"]')["href"]).to eq(admin_stock_path(stocks.third))
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

      it "メモを指定してStockを作成できる" do
        params = {
          stock: {
            plant_id: create_plant.id,
            location_id: create_location.id,
            growing_method: "pot",
            propagation_method: "cutting_soil",
            memo: "摘芯で作った挿し穂"
          }
        }

        post admin_stocks_path, params: params, headers: admin_headers

        created_stock = Stock.last
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

      update_button = Nokogiri::HTML(response.body)
                              .at_css('form.form-card .form-actions--sticky input[type="submit"][value="更新"]')
      expect(update_button).to be_present
    end

    it "ID順で前後のStock編集画面へ移動できる" do
      stocks = 3.times.map do |index|
        Stocks::Creator.call(
          plant_id: create_plant.id,
          location_id: create_location.id,
          growing_method: "pot",
          propagation_method: "seed",
          label: "ナビゲーション用株#{index}"
        )
      end

      get edit_admin_stock_path(stocks.second), headers: admin_headers

      document = Nokogiri::HTML(response.body)
      expect(document.at_css('a[rel="prev"]')["href"]).to eq(edit_admin_stock_path(stocks.first))
      expect(document.at_css('a[rel="next"]')["href"]).to eq(edit_admin_stock_path(stocks.third))
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
    end

    context "パラメータが不正な場合" do
      it "Stockを更新できない" do
        stock = create_stock
        patch admin_stock_path(stock, invalid_params), headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/stocks/:id" do
    it "Stockを削除できる" do
      stock = create_stock

      delete admin_stock_path(stock), headers: admin_headers

      expect(response).to redirect_to(admin_stocks_path)
      expect(flash[:notice]).to eq("削除しました")
    end
  end
end
