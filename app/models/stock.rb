# == 役割
# 個別の株または栽培単位を管理するモデル。
# 現在の状態、栽培方法、増殖方法、管理場所および親株との関係を保持する。
#
# == カラム
# id                 : 株ID
# plant_id           : 植物ID
# location_id        : 現在の管理場所ID
# parent_stock_id    : 増殖元となった親株ID
# code               : 株を識別する管理コード
# public_token       : 外部公開用トークン
# status             : 現在の管理状態
# growing_method     : 栽培方法
# propagation_method : 増殖方法
# completion_reason  : 育成完了理由
# completed_at       : 育成完了日時
# created_at         : 作成日時
# updated_at         : 更新日時
class Stock < ActiveRecord::Base
  has_secure_token :public_token

  belongs_to :plant
  belongs_to :location

  has_many :stock_action_logs, dependent: :destroy
  has_many :stock_observations, dependent: :destroy


  # 自己参照の関連
  belongs_to :parent_stock,          # parent_stock_idを外部キーとして使用
              class_name: "Stock",   # 別モデルを見ないようにStockモデル参照を指定
              optional: true         # 親株が存在しない場合もあるためoptional: trueを指定


  has_many :child_stocks,                  # child_stocksで子株の関連を取得
            class_name: "Stock",           # 別モデルを見ないようにStockモデル参照を指定
            foreign_key: :parent_stock_id  # 子株の外部キーとしてparent_stock_idを使用


  ########################
  # 定数
  ########################

  STATUS = {
    starting: "育成開始",
    rooting: "発根中",
    growing: "生育中",
    # dividing: "株分け中",
  }.freeze

  COMPLETION_REASON = {
    cultivation_ended: "育成終了",
    harvested: "収穫完了",
    discarded: "廃棄",
  }.freeze

  GROWING_METHOD = {
    pot: "苗ポット",
    planter: "プランター",
    water: "水耕",
  }.freeze

  PROPAGATION_METHOD = {
    cutting_soil: "土挿し",
    cutting_water: "水挿し",
    seed: "種まき",
  }.freeze

  #######################
  # scope
  #######################
  scope :active, -> { where(completed_at: nil) }
end
