# == 役割
# 種まき・挿し木による生産開始イベントの出自と開始条件を記録するモデル。
# 同じロット内でも苗ごとに進行速度が異なるため、現在工程や現在数量は持たない
#（それらはNurseryGroup・Stockが保持する）。
#
# == カラム
# id                 : 生産ロットID
# plant_id           : 対象植物ID
# source_stock_id    : 挿し穂を採取した親株ID（任意）
# propagation_method : 生産方法（播種/挿し木）
# started_on         : 生産開始日
# initial_quantity   : 開始数量
# memo               : メモ
# created_at         : 作成日時
# updated_at         : 更新日時
class ProductionLot < ApplicationRecord
  belongs_to :plant
  belongs_to :source_stock,
             class_name: "Stock",
             optional: true,
             inverse_of: :sourced_production_lots

  has_many :nursery_groups, dependent: :restrict_with_error
  has_many :stocks, through: :nursery_groups

  enum :propagation_method, {
    seed: "seed",
    cutting: "cutting"
  }, validate: true

  validates :started_on, presence: true
  validates :initial_quantity,
            numericality: { only_integer: true, greater_than: 0 }
  validate :source_stock_plant_matches

  # 播種は"sown"、挿し木は"rooting_wait"から工程を開始する
  def initial_stage
    seed? ? "sown" : "rooting_wait"
  end

  private

  # source_stockを設定する場合は、親株と同じplantでなければならない
  def source_stock_plant_matches
    return unless source_stock && plant
    return if source_stock.plant_id == plant_id

    errors.add(:source_stock, :invalid)
  end
end
