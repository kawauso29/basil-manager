require "rails_helper"

RSpec.describe "Public::Stocks", type: :request do
  let(:plant) { Plant.create!(name: "スイートバジル", code: "sweet_basil") }
  let(:location) { Location.create!(name: "室内棚", code: "indoor_shelf") }

  def create_stock(attributes = {})
    Stock.create!({
      plant: plant,
      location: location,
      stage: :growing,
      stage_started_on: Date.new(2026, 6, 10),
      potted_on: Date.new(2026, 6, 10)
    }.merge(attributes))
  end

  describe "GET /p/:token" do
    it "株の個体情報と育て方を認証なしで表示する" do
      stock = create_stock(product_type: :hydro)

      get public_stock_path(stock.public_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("スイートバジル")
      expect(response.body).to include("ST-#{stock.id}")
      expect(response.body).to include("2026年6月10日")
      expect(response.body).to include("商品が届いたら")
      expect(response.body).to include("育て方（室内・ハイドロ）")
      # 管理画面への導線と内部情報を出さない
      expect(response.body).not_to include("/admin")
      expect(response.body).not_to include("室内棚")
    end

    it "product_typeがsoilなら土版の育て方へ切り替わる" do
      stock = create_stock(product_type: :soil)

      get public_stock_path(stock.public_token)

      expect(response.body).to include("育て方（屋外・土）")
      expect(response.body).not_to include("育て方（室内・ハイドロ）")
    end

    it "存在しないトークンは404を返す" do
      get public_stock_path("does-not-exist")

      expect(response).to have_http_status(:not_found)
    end

    it "商品形態が未設定なら育て方を出さずに個体情報だけを表示する" do
      stock = create_stock

      get public_stock_path(stock.public_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("育成の記録")
      expect(response.body).not_to include("育て方（")
    end
  end
end
