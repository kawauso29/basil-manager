require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "管理対象と日常操作への導線を表示する" do
      get admin_root_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      links = Nokogiri::HTML(response.body).css("a").to_h do |link|
        [ link.text.strip, link["href"] ]
      end
      expect(links).to include(
        "株" => admin_stocks_path,
        "植物" => admin_plants_path,
        "場所" => admin_locations_path,
        "株を作成" => new_admin_stock_path,
        "データを出力" => admin_data_export_path
      )
    end
  end
end
