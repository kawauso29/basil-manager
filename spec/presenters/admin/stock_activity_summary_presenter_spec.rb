require "rails_helper"

RSpec.describe Admin::StockActivitySummaryPresenter do
  describe ".call" do
    it "直近の作業・観察をまとめる" do
      old_watered = double(
        action_type: "watered",
        action_type_i18n: "水やり",
        recorded_at: Time.zone.local(2026, 7, 25, 8),
        created_at: Time.zone.local(2026, 7, 25, 9)
      )
      latest_watered = double(
        action_type: "watered",
        action_type_i18n: "水やり",
        recorded_at: Time.zone.local(2026, 7, 27, 8),
        created_at: Time.zone.local(2026, 7, 27, 9)
      )
      fertilized = double(
        action_type: "fertilized",
        action_type_i18n: "施肥",
        recorded_at: nil,
        created_at: Time.zone.local(2026, 7, 28, 9)
      )
      observation = double(
        height_cm: 12.5,
        recorded_at: Time.zone.local(2026, 7, 28, 8),
        created_at: Time.zone.local(2026, 7, 28, 8)
      )
      summary = described_class.call(
        action_logs: [ old_watered, latest_watered, fertilized ],
        observations: [ observation ]
      )

      expect(summary.latest_action).to eq(
        label: "施肥",
        recorded_at: "日時未設定"
      )
      expect(summary.last_watered_action).to eq(
        label: "水やり",
        recorded_at: "2026/07/27 08:00"
      )
      expect(summary.last_fertilized_action).to eq(
        label: "施肥",
        recorded_at: "日時未設定"
      )
      expect(summary.latest_observation).to eq(
        height_cm: 12.5,
        recorded_at: "2026/07/28 08:00"
      )
    end

    it "記録がなければ空の状態を返す" do
      summary = described_class.call(
        action_logs: [],
        observations: []
      )

      expect(summary.latest_action).to be_nil
      expect(summary.last_watered_action).to be_nil
      expect(summary.last_fertilized_action).to be_nil
      expect(summary.latest_observation).to be_nil
    end
  end
end
