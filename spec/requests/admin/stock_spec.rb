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
    parent_stock.update!(parent_stock_candidate: true)
    child_stock = create_other_stock
    child_stock.update!(parent_stock_id: parent_stock.id)
    parent_stock
  end
  let(:create_child_stock) do
    parent_stock = create_stock
    parent_stock.update!(parent_stock_candidate: true)
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

    it "詳細・編集・数量変更画面で共通のレコード操作を表示する" do
      stock = create_stock

      {
        admin_stock_path(stock) => "詳細",
        edit_admin_stock_path(stock) => "編集",
        edit_quantity_admin_stock_path(stock) => "数量を変更"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="株の操作"]')
        expect(actions.text).to include(
          "詳細",
          "作業を記録",
          "観察を記録",
          "数量を変更",
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

    it "絞り込み結果の管理単位数と管理株数を表示する" do
      target_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 3
      )
      target_stock.update!(status: "growing")
      other_plant = Plant.create!(
        name: "集計対象外の植物",
        code: "excluded-summary-plant",
        prefix: "ESP"
      )
      Stocks::Creator.call(
        plant_id: other_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 7
      )

      get admin_stocks_path,
          params: { plant_id: create_plant.id, status: "growing" },
          headers: admin_headers

      document = Nokogiri::HTML(response.body)
      cards = document.css(".summary-card").to_h do |card|
        [ card.at_css("dt").text.strip, card.at_css("dd").text.squish ]
      end

      expect(cards).to include(
        "管理株数" => "3 株",
        "管理単位数" => "1 件"
      )
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
      expect(response.body).to include("数量を変更")
      expect(response.body).to include("編集")
      expect(response.body).to include("削除")
      document = Nokogiri::HTML(response.body)
      expect(document.css(".stock-card a").map { |link| link.text.strip }).not_to include("詳細")
    end

    it "直近の作業・観察と育成中の子株数を表示する" do
      stock = create_stock
      stock.update!(parent_stock_candidate: true)
      child_stock = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed",
        quantity: 3
      )
      child_stock.update!(parent_stock_id: stock.id)
      stock.stock_action_logs.create!(
        action_type: "watered",
        recorded_at: Time.zone.local(2026, 7, 27, 8)
      )
      stock.stock_action_logs.create!(
        action_type: "fertilized",
        recorded_at: Time.zone.local(2026, 7, 28, 9)
      )
      stock.stock_observations.create!(
        height_cm: 12.5,
        recorded_at: Time.zone.local(2026, 7, 28, 8)
      )

      get admin_stock_path(stock), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "直近の状況",
        "2026/07/27 08:00",
        "2026/07/28 09:00",
        "12.5 cm",
        "3 株"
      )
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
      expect(response.body).to include('name="stock[parent_stock_candidate]"')
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

      it "親株候補としてStockを作成できる" do
        params = valid_params.deep_merge(stock: { parent_stock_candidate: "1" })

        post admin_stocks_path, params: params, headers: admin_headers

        expect(Stock.last).to be_parent_stock_candidate
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

    it "同じ植物の育成中の親株候補だけを親株の選択肢に表示する" do
      stock = create_stock
      candidate = create_other_stock
      candidate.update!(parent_stock_candidate: true)
      non_candidate = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot"
      )
      completed_candidate = Stocks::Creator.call(
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        parent_stock_candidate: true
      )
      completed_candidate.update!(completed_at: Time.current, completion_reason: "cultivation_ended")
      other_plant = Plant.create!(name: "別の植物", code: "other", prefix: "OTH")
      other_plant_candidate = Stocks::Creator.call(
        plant_id: other_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        parent_stock_candidate: true
      )

      get edit_admin_stock_path(stock), headers: admin_headers

      option_values = Nokogiri::HTML(response.body)
                              .css('select[name="stock[parent_stock_id]"] option')
                              .filter_map { |option| option["value"].presence }
      expect(option_values).to contain_exactly(candidate.id.to_s)
      expect(option_values).not_to include(
        stock.id.to_s,
        non_candidate.id.to_s,
        completed_candidate.id.to_s,
        other_plant_candidate.id.to_s
      )
    end

    it "親株候補から外れた設定済みの親株は選択肢に残す" do
      child_stock = create_child_stock
      parent_stock = child_stock.parent_stock
      parent_stock.update!(parent_stock_candidate: false)

      get edit_admin_stock_path(child_stock), headers: admin_headers

      selected_option = Nokogiri::HTML(response.body)
                                .at_css('select[name="stock[parent_stock_id]"] option[selected]')
      expect(selected_option["value"]).to eq(parent_stock.id.to_s)
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

      it "親株候補フラグを更新できる" do
        stock = create_stock

        patch admin_stock_path(stock),
              params: { stock: { parent_stock_candidate: "1" } },
              headers: admin_headers

        expect(stock.reload).to be_parent_stock_candidate
      end

      it "親株候補のStockを親株に設定できる" do
        parent_stock = create_stock
        parent_stock.update!(parent_stock_candidate: true)
        child_stock = create_other_stock

        patch admin_stock_path(child_stock),
              params: { stock: { parent_stock_id: parent_stock.id } },
              headers: admin_headers

        expect(child_stock.reload.parent_stock).to eq(parent_stock)
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

      it "親株候補ではないStockを親株に設定できない" do
        parent_stock = create_stock
        child_stock = create_other_stock

        patch admin_stock_path(child_stock),
              params: { stock: { parent_stock_id: parent_stock.id } },
              headers: admin_headers

        expect(child_stock.reload.parent_stock).to be_nil
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("親株候補に設定されている株を選択してください")
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
