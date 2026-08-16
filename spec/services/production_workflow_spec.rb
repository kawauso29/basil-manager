require "rails_helper"

RSpec.describe "Production workflow services" do
  let(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let(:location) { Location.create!(name: "育苗棚", code: "nursery") }
  let(:started_on) { Date.new(2026, 8, 1) }

  def start_production(propagation_method: :seed, quantity: 10, growing_method: :soil)
    StartProduction.call(
      plant_id: plant.id,
      propagation_method: propagation_method,
      started_on: started_on,
      initial_quantity: quantity,
      location_id: location.id,
      growing_method: growing_method
    )
  end

  describe StartProduction do
    it "Lotと初期グループを同じトランザクションで作る" do
      lot = start_production

      expect(lot).to have_attributes(
        plant: plant,
        propagation_method: "seed",
        started_on: started_on,
        initial_quantity: 10
      )
      expect(lot.nursery_groups.sole).to have_attributes(
        location: location,
        stage: "sown",
        growing_method: "soil",
        quantity: 10,
        stage_started_on: started_on
      )
    end

    it "初期グループを保存できなければLotも残さない" do
      expect {
        StartProduction.call(
          plant_id: plant.id,
          propagation_method: :seed,
          started_on: started_on,
          initial_quantity: 10,
          location_id: location.id,
          growing_method: :water,
          container_type: nil
        )
      }.to change(ProductionLot, :count).by(1)

      lot_count = ProductionLot.count
      expect {
        StartProduction.call(
          plant_id: plant.id,
          propagation_method: :seed,
          started_on: started_on,
          initial_quantity: 10,
          location_id: -1,
          growing_method: :soil
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(ProductionLot.count).to eq(lot_count)
    end
  end

  describe AdvanceNurseryGroup do
    it "全数なら同じ行を直後の工程へ進める" do
      group = start_production.nursery_groups.sole

      result = described_class.call(
        nursery_group: group,
        quantity: 10,
        recorded_on: Date.new(2026, 8, 5)
      )

      expect(result).to eq(group)
      expect(group.reload).to have_attributes(
        stage: "germinating",
        quantity: 10,
        stage_started_on: Date.new(2026, 8, 5)
      )
    end

    it "一部なら元数量を減らして次工程グループを作る" do
      group = start_production.nursery_groups.sole

      advanced_group = described_class.call(
        nursery_group: group,
        quantity: 4,
        recorded_on: Date.new(2026, 8, 5)
      )

      expect(group.reload.quantity).to eq(6)
      expect(advanced_group).to have_attributes(
        production_lot: group.production_lot,
        stage: "germinating",
        quantity: 4,
        stage_started_on: Date.new(2026, 8, 5)
      )
    end

    it "現在数量を超える進行を拒否する" do
      group = start_production.nursery_groups.sole

      expect {
        described_class.call(nursery_group: group, quantity: 11, recorded_on: Date.current)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(group.reload.quantity).to eq(10)
    end

    it "先読みした古いインスタンスでも残数を再読込して数量競合を拒否する" do
      group = start_production.nursery_groups.sole
      stale_group = NurseryGroup.find(group.id)

      described_class.call(
        nursery_group: group,
        quantity: 7,
        recorded_on: Date.new(2026, 8, 5)
      )
      group_count = NurseryGroup.count

      expect {
        described_class.call(
          nursery_group: stale_group,
          quantity: 4,
          recorded_on: Date.new(2026, 8, 6)
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(group.reload.quantity).to eq(3)
      expect(NurseryGroup.count).to eq(group_count)
    end
  end

  describe CorrectNurseryGroupQuantity do
    it "0を含む現在数量へロック下で補正する" do
      group = start_production.nursery_groups.sole

      result = described_class.call(nursery_group: group, quantity: 0)

      expect(result).to eq(group)
      expect(group.reload.quantity).to eq(0)
    end

    it "負数を拒否して元数量を残す" do
      group = start_production.nursery_groups.sole

      expect {
        described_class.call(nursery_group: group, quantity: -1)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(group.reload.quantity).to eq(10)
    end
  end

  describe PotUpNurseryGroup do
    it "鉢上げ可能グループの数量を減らして個体Stockを作る" do
      lot = start_production(propagation_method: :cutting, quantity: 5, growing_method: :water)
      group = lot.nursery_groups.sole
      AdvanceNurseryGroup.call(nursery_group: group, quantity: 5, recorded_on: Date.new(2026, 8, 5))
      AdvanceNurseryGroup.call(nursery_group: group, quantity: 5, recorded_on: Date.new(2026, 8, 10))
      potted_on = Date.new(2026, 8, 15)

      stocks = described_class.call(
        nursery_group: group,
        quantity: 3,
        location_id: location.id,
        potted_on: potted_on
      )

      expect(group.reload.quantity).to eq(2)
      expect(stocks.size).to eq(3)
      expect(stocks).to all have_attributes(
        plant: plant,
        location: location,
        source_nursery_group: group,
        stage: "acclimating",
        stage_started_on: potted_on,
        potted_on: potted_on
      )
      expect(stocks.map(&:public_token)).to all(be_present)
      expect(stocks.map(&:public_token).uniq.size).to eq(3)
    end

    it "先読みした古いインスタンスでも残数を再読込して過剰鉢上げを拒否する" do
      lot = start_production(propagation_method: :cutting, quantity: 5, growing_method: :water)
      group = lot.nursery_groups.sole
      AdvanceNurseryGroup.call(nursery_group: group, quantity: 5, recorded_on: Date.new(2026, 8, 5))
      AdvanceNurseryGroup.call(nursery_group: group, quantity: 5, recorded_on: Date.new(2026, 8, 10))
      stale_group = NurseryGroup.find(group.id)

      described_class.call(
        nursery_group: group,
        quantity: 4,
        location_id: location.id,
        potted_on: Date.new(2026, 8, 15)
      )
      stock_count = Stock.count

      expect {
        described_class.call(
          nursery_group: stale_group,
          quantity: 2,
          location_id: location.id,
          potted_on: Date.new(2026, 8, 15)
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(group.reload.quantity).to eq(1)
      expect(Stock.count).to eq(stock_count)
    end

    it "鉢上げ可能前のグループを変更しない" do
      group = start_production.nursery_groups.sole

      stock_count = Stock.count
      expect {
        described_class.call(
          nursery_group: group,
          quantity: 1,
          location_id: location.id,
          potted_on: Date.current
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Stock.count).to eq(stock_count)

      expect(group.reload.quantity).to eq(10)
    end
  end
end
