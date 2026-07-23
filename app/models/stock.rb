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

  enum :status, {
    starting: "starting",
    rooting: "rooting",
    growing: "growing"
  }, validate: true

  enum :completion_reason, {
    cultivation_ended: "cultivation_ended",
    harvested: "harvested",
    discarded: "discarded"
  }, validate: { allow_blank: true }

  # どうやって育てるかを定義している。
  # ポット、プランター、植木鉢などのサイズは
  # 別途カラムを追加して管理することとする。
  enum :growing_method, {
    pot: "pot",
    planter: "planter",
    flowerpot: "flowerpot",
    water: "water",
    other: "other",
  }, validate: true

  enum :propagation_method, {
    cutting_soil: "cutting_soil",
    cutting_water: "cutting_water",
    seed: "seed"
  }, validate: true

  #######################
  # scope
  #######################
  scope :active, -> { where(completed_at: nil) }
end
