require "rails_helper"

RSpec.describe NurseryGroup, type: :model do
  let(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let(:location) { Location.create!(name: "育苗棚", code: "nursery") }

  def create_lot(propagation_method)
    ProductionLot.create!(
      plant: plant,
      propagation_method: propagation_method,
      started_on: Date.current,
      initial_quantity: 2
    )
  end

  it "数量は0以上に限る" do
    group = described_class.new(
      production_lot: create_lot(:seed),
      location: location,
      stage: :sown,
      growing_method: :soil,
      quantity: -1,
      stage_started_on: Date.current
    )

    expect(group).not_to be_valid
  end

  it "生産方法と異なる工程を拒否する" do
    group = described_class.new(
      production_lot: create_lot(:seed),
      location: location,
      stage: :rooting_wait,
      growing_method: :soil,
      quantity: 1,
      stage_started_on: Date.current
    )

    expect(group).not_to be_valid
  end

  it "直後の工程を返し、鉢上げ可能工程には次工程がない" do
    group = described_class.new(stage: :germinating)
    ready_group = described_class.new(stage: :pot_up_ready)

    expect(group.next_stage).to eq("thinning")
    expect(ready_group.next_stage).to be_nil
  end
end
