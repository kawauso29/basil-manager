require "rails_helper"

RSpec.describe ProductionLot, type: :model do
  let(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let(:location) { Location.create!(name: "育苗棚", code: "nursery") }

  it "開始数量は正の整数に限る" do
    lot = described_class.new(
      plant: plant,
      propagation_method: :seed,
      started_on: Date.current,
      initial_quantity: 0
    )

    expect(lot).not_to be_valid
  end

  it "親株は同じ植物に限る" do
    other_plant = Plant.create!(name: "タイム", code: "thyme")
    source_stock = Stock.create!(
      plant: other_plant,
      location: location,
      stage: :growing,
      stage_started_on: Date.current
    )
    lot = described_class.new(
      plant: plant,
      source_stock: source_stock,
      propagation_method: :cutting,
      started_on: Date.current,
      initial_quantity: 1
    )

    expect(lot).not_to be_valid
  end

  it "生産方法に応じた初期工程を返す" do
    seed_lot = described_class.new(propagation_method: :seed)
    cutting_lot = described_class.new(propagation_method: :cutting)

    expect(seed_lot.initial_stage).to eq("sown")
    expect(cutting_lot.initial_stage).to eq("rooting_wait")
  end
end
