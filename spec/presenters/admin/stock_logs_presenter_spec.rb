require "rails_helper"

RSpec.describe Admin::StockLogsPresenter do
  describe ".call" do
    it "作業ログと観察ログを古い順に整形する" do
      action_log = double(
        recorded_at: Time.zone.local(2026, 7, 2, 9),
        created_at: Time.zone.local(2026, 7, 2, 10),
        action_type_i18n: "水やり",
        memo: "新しい作業ログ"
      )
      observation_log = double(
        recorded_at: Time.zone.local(2026, 7, 1, 8),
        created_at: Time.zone.local(2026, 7, 1, 9),
        height_cm: 10,
        image_small_path: "test",
        image: "normal",
        memo: "古い観察ログ"
      )

      result = described_class.call(
        [ action_log ],
        [ observation_log ]
      )

      expect(result).to eq(
        [
          {
            recorded_at: "2026年07月01日08時",
            label: "観察",
            data_value: "10 cm",
            image_thumbnail_path: "test",
            image_path: "normal",
            memo: "古い観察ログ"
          },
          {
            recorded_at: "2026年07月02日09時",
            label: "水やり",
            data_value: nil,
            image_thumbnail_path: "",
            image_path: "",
            memo: "新しい作業ログ"
          }
        ]
      )
    end

    it "記録日時が未確定のログは登録日時で並べ、表示日時は空欄にする" do
      action_log = double(
        recorded_at: nil,
        created_at: Time.zone.local(2026, 7, 2, 9),
        action_type_i18n: "水やり",
        memo: "記録日時未確定の作業ログ"
      )
      observation_log = double(
        recorded_at: Time.zone.local(2026, 7, 1, 8),
        created_at: Time.zone.local(2026, 7, 3, 9),
        height_cm: 10,
        image_small_path: "test",
        image: "normal",
        memo: "記録日時が確定した観察ログ"
      )

      result = described_class.call([ action_log ], [ observation_log ])

      expect(result.pluck(:label)).to eq([ "観察", "水やり" ])
      expect(result.last[:recorded_at]).to be_nil
    end

    it "ログがなければ空配列を返す" do
      result = described_class.call([], [])

      expect(result).to eq([])
    end
  end
end
