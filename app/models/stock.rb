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

# 重要
# parent_stock_idがある場合: 子が確定。必ず親株を持つ。
# => ただし自身が子でもさらに子を持つ場合は子でもあり親でもあることが成り立つ。
# parent_stock_idがない場合: 親であることは確定しない。子から指定されていれば親が確定。指定されていなければ親株ではない。

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
            foreign_key: :parent_stock_id, # 子株の外部キーとしてparent_stock_idを使用
            dependent: :restrict_with_error

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

  validate :valid_cannot_self_be_parent

  #######################
  # scope
  #######################
  scope :active, -> { where(completed_at: nil) }
  scope :parents, -> { where(id: parent_select_relation) }
  scope :children, -> { where.not(parent_stock_id: nil) }

  # n+1注意
  # => パフォーマンスに影響するようならchild_idカラムを増やして
  # 関連付けは専用フォームに切り出す
  def parent?
    ids = self.class.parent_select_relation.pluck(:parent_stock_id)
    ids.include?(self.id)
  end
  def child?
    self.parent_stock_id.present?
  end
  def not_child?
    !child?
  end
  def has_parent?
    child?
  end
  def has_children?
    self.child_stocks.exists?
  end

  # parent_stock_idに指定されているstock_idの関連を抜き出す
  def self.parent_select_relation
    cache_key = "stock_parent_ids_#{Stock.active.maximum(:updated_at)}"
    select_rel = Rails.cache.fetch(cache_key) do
      Stock.active.children.select(:parent_stock_id)
    end
    select_rel
  end

  private

  def valid_cannot_self_be_parent
    return if parent_stock_id.nil?

    if parent_stock_id == id
      errors.add(:parent_stock_id, :cannot_be_self)
    end
  end
end
