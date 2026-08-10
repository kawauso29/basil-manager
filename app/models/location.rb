# == 役割
# 株を保管または栽培する場所を管理するマスターモデル。
# 株の現在地としてStockから参照される。
#
# == カラム
# id         : 管理場所ID
# code       : 管理場所を識別するコード
# prefix     : 管理場所のプレフィックス
# name       : 管理場所名
# environment: 屋内・屋外の区分
# created_at : 作成日時
# updated_at : 更新日時
class Location < ActiveRecord::Base
  has_one_attached :image do |attachable|
    attachable.variant :icon_thumb, resize_to_limit: [ 100, 100 ], preprocessed: true
    attachable.variant :main_thumb, resize_to_limit: [ 300, 300 ], preprocessed: true
  end

  # 子を1つでも持つ場合は削除せず引き止めます。
  has_many :stocks, dependent: :restrict_with_error
  has_many :outgoing_stock_action_logs,
           class_name: "StockActionLog",
           foreign_key: :from_location_id,
           dependent: :restrict_with_error
  has_many :incoming_stock_action_logs,
           class_name: "StockActionLog",
           foreign_key: :to_location_id,
           dependent: :restrict_with_error

  enum :environment, {
    indoor: "indoor",
    outdoor: "outdoor"
  }, validate: true

  validates :name,   presence: true,  uniqueness: true
  validates :prefix, presence: true,  uniqueness: true
  validates :code,   presence: true,  uniqueness: true

  def has_image?
    self.image.attached?
  end
  def missing_image?
    !has_image?
  end
  def icon_path
    return "" if missing_image?
    self.image.variant(:icon_thumb)
  end
  def thumb_path
    return "" if missing_image?
    self.image.variant(:main_thumb)
  end
end
