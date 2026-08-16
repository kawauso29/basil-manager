# == 役割
# 植物の種類を管理するマスターモデル。
# 生産ロットと個体株が参照する植物・品種を保持する。
#
# == カラム
# id                : 植物ID
# code              : 植物を識別する管理コード
# name              : 植物名
# scientific_name   : 学名
# created_at        : 作成日時
# updated_at        : 更新日時
class Plant < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :icon_thumb, resize_to_limit: [ 100, 100 ], preprocessed: true
    attachable.variant :main_thumb, resize_to_limit: [ 300, 300 ], preprocessed: true
  end

  has_many :production_lots, dependent: :restrict_with_error
  has_many :stocks, dependent: :restrict_with_error

  validates :name,   presence: true,  uniqueness: true
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
