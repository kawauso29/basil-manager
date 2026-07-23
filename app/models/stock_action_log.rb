# == 役割
# 株に対して行った栽培作業を時系列で記録するモデル。
# 株の現在値ではなく、いつ何を行ったかという履歴を保持する。
#
# == カラム
# id          : 作業記録ID
# stock_id    : 対象の株ID
# action_type : 作業の種類
# memo        : 作業内容の補足
# recorded_at : 作業を行った日時
# created_at  : 登録日時
# updated_at  : 更新日時
class StockActionLog < ActiveRecord::Base
  belongs_to :stock

  enum :action_type, {
    seed_sown: "seed_sown",
    cutting_started: "cutting_started",
    watered: "watered",
    fertilized: "fertilized",
    pinched: "pinched",
    pruned: "pruned",
    water_replaced: "water_replaced",
    harvested: "harvested",
    moved: "moved",
    transplanted: "transplanted"
  }, validate: true
end
