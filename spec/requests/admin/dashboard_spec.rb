require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "生産管理と日常操作への導線を表示する" do
      get admin_root_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      links = Nokogiri::HTML(response.body).css("a").to_h do |link|
        [ link.text.strip, link["href"] ]
      end
      expect(links).to include(
        "生産ロット" => admin_production_lots_path,
        "苗グループ" => admin_nursery_groups_path,
        "株" => admin_stocks_path,
        "植物" => admin_plants_path,
        "場所" => admin_locations_path,
        "生産を開始" => new_admin_production_lot_path,
        "株を直接登録" => new_admin_stock_path,
        "観察を記録" => new_admin_stock_observation_path,
        "AI提供用ZIPを出力" => admin_data_export_path
      )
      expect(response.body).not_to include("作業履歴", "アクションを一括記録")
    end
  end
end
