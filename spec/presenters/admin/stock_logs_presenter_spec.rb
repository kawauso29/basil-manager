require "rails_helper"

RSpec.describe Admin::StockLogsPresenter do
  describe ".call" do
    it "作業ログと観察ログを古い順に整形する" do
      action_log = double(
        recorded_at: Time.zone.local(2026, 7, 2, 9),
        action_type_i18n: "水やり",
        memo: "新しい作業ログ"
      )
      observation_log = double(
        recorded_at: Time.zone.local(2026, 7, 1, 8),
        height_cm: 10,
        memo: "古い観察ログ"
      )

      result = described_class.call(
        [action_log],
        [observation_log]
      )

      expect(result).to eq(
        [
          {
            recorded_at: "2026年07月01日08時",
            label: "観察",
            data_value: "10 cm",
            memo: "古い観察ログ"
          },
          {
            recorded_at: "2026年07月02日09時",
            label: "水やり",
            data_value: nil,
            memo: "新しい作業ログ"
          }
        ]
      )
    end

    it "ログがなければ空配列を返す" do
      result = described_class.call([], [])

      expect(result).to eq([])
    end
  end
end
