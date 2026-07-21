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
  has_many :stocks
  has_many :location_observations, dependent: :destroy
end
