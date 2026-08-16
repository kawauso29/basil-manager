require "rails_helper"
require "stringio"

RSpec.describe StockObservation, type: :model do
  let(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let(:location) { Location.create!(name: "育苗棚", code: "nursery") }
  let(:stock) do
    Stock.create!(
      plant: plant,
      location: location,
      stage: :growing,
      stage_started_on: Date.current
    )
  end

  it "記録日時と、草丈・メモ・画像のいずれかを要求する" do
    observation = described_class.new(stock: stock, recorded_at: Time.current)

    expect(observation).not_to be_valid

    observation.image.attach(
      io: StringIO.new("image"),
      filename: "observation.png",
      content_type: "image/png"
    )

    expect(observation).to be_valid
  end

  it "負の草丈を拒否する" do
    observation = described_class.new(
      stock: stock,
      recorded_at: Time.current,
      height_cm: -0.1
    )

    expect(observation).not_to be_valid
  end
end
