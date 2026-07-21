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

  ACTION_TYPE = {
    seed_sown: "種まき",
    cutting_started: "挿し木開始",
    watered: "水やり",
    fertilized: "施肥",
    pinched: "摘芯",
    pruned: "剪定",
    # divided: "株分け",
    water_replaced: "水交換",
    harvested: "収穫",
    moved: "管理場所変更",
    transplanted: "植え替え",
  }.freeze
end
