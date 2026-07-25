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
  has_one_attached :image do |attachable|
    attachable.variant :small, resize_to_limit: [ 100, 100 ], preprocessed: true
    attachable.variant :normal, resize_to_limit: [ 300, 300 ]
  end

  def has_image?
    self.image.attached?
  end
  def missing_image?
    !has_image?
  end
  def image_small_path
    return "" if missing_image?
    self.image.variant(:small)
  end
  def image_normal_path
    return "" if missing_image?
    self.image.variant(:normal)
  end
end
