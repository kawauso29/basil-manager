require "rails_helper"

RSpec.describe Stock, type: :model do
  let(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let(:location) { Location.create!(name: "育苗棚", code: "nursery") }

  def create_stock(attributes = {})
    described_class.create!({
      plant: plant,
      location: location,
      stage: :acclimating,
      stage_started_on: Date.new(2026, 8, 15)
    }.merge(attributes))
  end

  describe ".register_direct!" do
    it "鉢上げ元なしの個体Stockを直接登録する" do
      stock = described_class.register_direct!(
        plant_id: plant.id,
        location_id: location.id,
        stage: :growing,
        stage_started_on: Date.new(2026, 8, 15),
        memo: "購入株"
      )

      expect(stock).to have_attributes(
        plant: plant,
        location: location,
        source_nursery_group: nil,
        stage: "growing",
        potted_on: nil,
        memo: "購入株"
      )
      expect(stock.public_token).to be_present
    end
  end

  describe "鉢上げ元" do
    it "鉢上げ元がある場合は同じ植物と鉢上げ日を要求する" do
      lot = ProductionLot.create!(
        plant: plant,
        propagation_method: :cutting,
        started_on: Date.new(2026, 8, 1),
        initial_quantity: 2
      )
      group = lot.nursery_groups.create!(
        location: location,
        stage: :pot_up_ready,
        growing_method: :water,
        quantity: 2,
        stage_started_on: Date.new(2026, 8, 10)
      )
      other_plant = Plant.create!(name: "タイム", code: "thyme")

      missing_date = described_class.new(
        plant: plant,
        location: location,
        source_nursery_group: group,
        stage: :acclimating,
        stage_started_on: Date.new(2026, 8, 15)
      )
      wrong_plant = missing_date.dup
      wrong_plant.plant = other_plant
      wrong_plant.potted_on = Date.new(2026, 8, 15)

      expect(missing_date).not_to be_valid
      expect(wrong_plant).not_to be_valid
    end

    it "StockとLotの双方からthrough関連を取得する" do
      lot = ProductionLot.create!(
        plant: plant,
        propagation_method: :seed,
        started_on: Date.new(2026, 8, 1),
        initial_quantity: 1
      )
      group = lot.nursery_groups.create!(
        location: location,
        stage: :pot_up_ready,
        growing_method: :soil,
        quantity: 1,
        stage_started_on: Date.new(2026, 8, 10)
      )
      stock = create_stock(source_nursery_group: group, potted_on: Date.new(2026, 8, 15))

      expect(stock.production_lot).to eq(lot)
      expect(lot.stocks).to contain_exactly(stock)
    end
  end

  describe "工程と販売可能状態" do
    it "acclimatingからgrowingへだけ進行できる" do
      stock = create_stock

      stock.advance_stage!(stage_started_on: Date.new(2026, 8, 20))

      expect(stock).to have_attributes(stage: "growing", stage_started_on: Date.new(2026, 8, 20))
      expect {
        stock.advance_stage!(stage_started_on: Date.new(2026, 8, 21))
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "生育中の株だけに販売可能日を設定し、空の日付を拒否する" do
      stock = create_stock(stage: :growing)

      expect { stock.mark_sale_ready!(on: nil) }.to raise_error(ActiveRecord::RecordInvalid)

      stock.mark_sale_ready!(on: Date.new(2026, 8, 25))

      expect(stock).to be_sale_ready
      expect(described_class.sale_ready).to contain_exactly(stock)
    end

    it "完了時に販売可能日を保持するが有効な販売可能株からは外す" do
      stock = create_stock(stage: :growing, sale_ready_on: Date.new(2026, 8, 25))

      stock.complete!(reason: :transferred, at: Time.zone.local(2026, 8, 30, 10))

      expect(stock.sale_ready_on).to eq(Date.new(2026, 8, 25))
      expect(stock).not_to be_sale_ready
      expect(described_class.sale_ready).not_to include(stock)
    end

    it "販売可能を解除できる" do
      stock = create_stock(stage: :growing, sale_ready_on: Date.new(2026, 8, 25))

      stock.revoke_sale_ready!

      expect(stock.sale_ready_on).to be_nil
    end
  end

  describe "最新草丈" do
    it "recorded_at降順、同時刻ではid降順の最新草丈を返す" do
      stock = create_stock
      recorded_at = Time.zone.local(2026, 8, 20, 9)
      stock.stock_observations.create!(height_cm: 8, recorded_at: recorded_at - 1.day)
      stock.stock_observations.create!(height_cm: 9, recorded_at: recorded_at)
      latest = stock.stock_observations.create!(height_cm: 10, recorded_at: recorded_at)

      expect(stock.latest_height_observation).to eq(latest)
      expect(stock.latest_height_cm).to eq(10)
    end
  end

  describe "#display_name" do
    it "IDを個体表示名にする" do
      stock = create_stock

      expect(stock.display_name).to eq("ST-#{stock.id}")
    end
  end

  describe "#public_url" do
    it "公開ページのURLを組み立てる" do
      stock = create_stock

      expect(stock.public_url)
        .to eq("#{described_class::PUBLIC_BASE_URL}/p/#{stock.public_token}")
    end

    # 印刷して鉢に貼ったQRコードは直せないため、ルーティングとの食い違いを検知する
    it "routes.rbの公開ページのパスと一致する" do
      stock = create_stock
      path = Rails.application.routes.url_helpers.public_stock_path(stock.public_token)

      expect(stock.public_url).to end_with(path)
    end
  end

  describe "#product_type" do
    it "商品形態は空でもよい" do
      expect(create_stock.product_type).to be_nil
    end

    it "未定義の商品形態を拒否する" do
      stock = create_stock
      stock.product_type = "unknown"

      expect(stock).not_to be_valid
      expect(stock.errors.details[:product_type]).to include(error: :inclusion, value: "unknown")
    end
  end
end
