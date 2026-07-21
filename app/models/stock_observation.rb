# == 役割
# 株を観察した時点の測定値とメモを時系列で記録するモデル。
# 栽培作業の履歴とは分けて、株の成長過程を保持する。
#
# == カラム
# id          : 株観察記録ID
# stock_id    : 観察対象の株ID
# height_cm   : 観察時点の高さ（cm）
# memo        : 観察内容の補足
# recorded_at : 観察した日時
# created_at  : 登録日時
# updated_at  : 更新日時
class StockObservation < ActiveRecord::Base
  belongs_to :stock
end
