require "rails_helper"

RSpec.describe "Admin::StockObservations", type: :request do
  let!(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let!(:location) do
    Location.create!(name: "育成棚", code: "growing-shelf", environment: "indoor")
  end
  let!(:stock) do
    Stock.register_direct!(
      plant_id: plant.id,
      location_id: location.id,
      stage: "growing",
      stage_started_on: Date.new(2026, 8, 14)
    )
  end

  describe "GET /admin/stock_observations" do
    it "新しい観察日時順でST-IDを表示する" do
      old_observation = stock.stock_observations.create!(
        height_cm: 8,
        recorded_at: Time.zone.local(2026, 8, 14, 9)
      )
      new_observation = stock.stock_observations.create!(
        memo: "新しい観察",
        recorded_at: Time.zone.local(2026, 8, 15, 9)
      )

      get admin_stock_observations_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      rows = document.css("tbody tr")
      expect(rows.first.text).to include("新しい観察", "ST-#{stock.id}")
      expect(rows.last.text).to include(old_observation.height_cm.to_s)
      expect(new_observation.recorded_at).to be > old_observation.recorded_at
    end
  end

  describe "GET /admin/stock_observations/new" do
    it "必須の観察日時と内容入力を表示する" do
      get new_admin_stock_observation_path(stock_id: stock.id), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "ST-#{stock.id}",
        'name="stock_observation[recorded_at]"',
        'name="stock_observation[height_cm]"',
        'name="stock_observation[image]"'
      )
      recorded_at_input = Nokogiri::HTML(response.body).at_css(
        'input[name="stock_observation[recorded_at]"]'
      )
      expect(recorded_at_input["required"]).to be_present
    end
  end

  describe "GET /admin/stock_observations/:id" do
    it "観察時点の値と必須の観察日時を表示する" do
      observation = stock.stock_observations.create!(
        height_cm: 10.5,
        memo: "詳細確認",
        recorded_at: Time.zone.local(2026, 8, 15, 9, 30)
      )

      get admin_stock_observation_path(observation), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ST-#{stock.id}", "10.5 cm", "2026/08/15 09:30", "詳細確認")
    end
  end

  describe "GET /admin/stock_observations/:id/edit" do
    it "観察日時を必須とする編集フォームを表示する" do
      observation = stock.stock_observations.create!(
        memo: "編集対象",
        recorded_at: Time.zone.local(2026, 8, 15, 9)
      )

      get edit_admin_stock_observation_path(observation), headers: admin_headers

      expect(response).to have_http_status(:ok)
      recorded_at_input = Nokogiri::HTML(response.body).at_css(
        'input[name="stock_observation[recorded_at]"]'
      )
      expect(recorded_at_input["required"]).to be_present
    end
  end

  describe "POST /admin/stock_observations" do
    it "草丈を観察日時付きで記録する" do
      expect {
        post admin_stock_observations_path,
             params: {
               stock_observation: {
                 stock_id: stock.id,
                 height_cm: "12.5",
                 memo: "順調",
                 recorded_at: "2026-08-15T09:30"
               }
             },
             headers: admin_headers
      }.to change(StockObservation, :count).by(1)

      observation = StockObservation.last
      expect(response).to redirect_to(admin_stock_observations_path)
      expect(observation).to have_attributes(
        stock_id: stock.id,
        height_cm: 12.5,
        memo: "順調",
        recorded_at: Time.zone.local(2026, 8, 15, 9, 30)
      )
    end

    it "観察日時がなければ保存しない" do
      expect {
        post admin_stock_observations_path,
             params: {
               stock_observation: {
                 stock_id: stock.id,
                 memo: "日時なし",
                 recorded_at: ""
               }
             },
             headers: admin_headers
      }.not_to change(StockObservation, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "草丈・メモ・画像がすべて空なら保存しない" do
      expect {
        post admin_stock_observations_path,
             params: {
               stock_observation: {
                 stock_id: stock.id,
                 height_cm: "",
                 memo: "",
                 recorded_at: "2026-08-15T09:30"
               }
             },
             headers: admin_headers
      }.not_to change(StockObservation, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/stock_observations/:id" do
    it "観察値と日時を更新する" do
      observation = stock.stock_observations.create!(
        memo: "更新前",
        recorded_at: Time.zone.local(2026, 8, 14, 9)
      )

      patch admin_stock_observation_path(observation),
            params: {
              stock_observation: {
                height_cm: "15.2",
                memo: "更新後",
                recorded_at: "2026-08-15T10:00"
              }
            },
            headers: admin_headers

      expect(response).to redirect_to(admin_stock_observation_path(observation))
      expect(observation.reload).to have_attributes(
        height_cm: 15.2,
        memo: "更新後",
        recorded_at: Time.zone.local(2026, 8, 15, 10)
      )
    end
  end

  describe "DELETE /admin/stock_observations/:id" do
    it "観察記録を削除する" do
      observation = stock.stock_observations.create!(
        memo: "削除対象",
        recorded_at: Time.zone.local(2026, 8, 15, 9)
      )

      expect {
        delete admin_stock_observation_path(observation), headers: admin_headers
      }.to change(StockObservation, :count).by(-1)

      expect(response).to redirect_to(admin_stock_observations_path)
    end
  end
end
