# == 役割
# 植物の種類を管理するマスターモデル。
# 株の管理コードに使うプレフィックスと、最後に発行した株番号を保持する。
#
# == カラム
# id                : 植物ID
# code              : 植物を識別する管理コード
# prefix            : 株の管理コードに使用するプレフィックス
# name              : 植物名
# last_stock_number : 最後に発行した株番号
# created_at        : 作成日時
# updated_at        : 更新日時
class Plant < ActiveRecord::Base

  # stocksを1つでも持つ場合は削除せず、エラーを返し引き止めます。
  has_many :stocks, dependent: :restrict_with_error

  validates :name,   presence: true,  uniqueness: true
  validates :prefix, presence: true,  uniqueness: true
  validates :code,   presence: true,  uniqueness: true
end
