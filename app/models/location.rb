# == 役割
# 株を保管または栽培する場所を管理するマスターモデル。
# 株の現在地と、場所単位の環境観察記録の参照先になる。
#
# == カラム
# id         : 管理場所ID
# code       : 管理場所を識別するコード
# prefix     : 管理場所のプレフィックス
# name       : 管理場所名
# created_at : 作成日時
# updated_at : 更新日時
class Location < ActiveRecord::Base

  # 子を1つでも持つ場合は削除せず引き止めます。
  has_many :stocks, dependent: :restrict_with_error
  has_many :location_observations, dependent: :restrict_with_error

  validates :name,   presence: true,  uniqueness: true
  validates :prefix, presence: true,  uniqueness: true
  validates :code,   presence: true,  uniqueness: true
end
