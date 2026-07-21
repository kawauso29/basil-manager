# == 役割
# 管理場所の気温や天候などの環境情報を時系列で記録するモデル。
# 同じ場所で管理する複数の株に共通する観察情報を保持する。
#
# == カラム
# id          : 場所観察記録ID
# location_id : 観察対象の管理場所ID
# temperature : 観察時点の気温（℃）
# weather     : 観察時点の天候
# memo        : 観察内容の補足
# recorded_at : 観察した日時
# created_at  : 登録日時
# updated_at  : 更新日時
class LocationObservation < ActiveRecord::Base
  belongs_to :location

  WEATHER = {
    sunny: "晴れ",
    cloudy: "曇り",
    rainy: "雨",
    snowy: "雪"
  }.freeze
end
