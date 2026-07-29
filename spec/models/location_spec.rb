require "rails_helper"

RSpec.describe Location, type: :model do
  describe "#latest_observation" do
    it "recorded_atがあればその日時、なければcreated_atで最新を判定する" do
      location = Location.create!(
        name: "最新観察を確認する場所",
        code: "latest-observation",
        prefix: "LOB"
      )
      LocationObservation.create!(
        location: location,
        memo: "日時設定済み",
        recorded_at: Time.zone.local(2026, 7, 27, 8),
        created_at: Time.zone.local(2026, 7, 27, 9)
      )
      latest_observation = LocationObservation.create!(
        location: location,
        memo: "日時未設定の最新記録",
        recorded_at: nil,
        created_at: Time.zone.local(2026, 7, 28, 9)
      )

      expect(location.latest_observation).to eq(latest_observation)
    end

    it "観察記録がなければnilを返す" do
      location = Location.create!(
        name: "観察記録がない場所",
        code: "no-observation",
        prefix: "NOB"
      )

      expect(location.latest_observation).to be_nil
    end
  end
end
