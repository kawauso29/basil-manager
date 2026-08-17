# == 役割
# 鉢上げ前の苗を、同じ工程・育成条件を共有する数量単位で管理するモデル。
# 工程が進むごとに数量を分割・更新し、鉢上げによってStockへ切り替わる。
#
# == カラム
# id                : 苗グループID
# production_lot_id : 生産ロットID
# location_id       : 現在の管理場所ID
# stage             : 現在の生産工程
# growing_method    : 育成方法
# container_type    : 容器種類
# quantity          : 現在数量
# stage_started_on  : 現工程の開始日
# memo              : メモ
# created_at        : 作成日時
# updated_at        : 更新日時
class NurseryGroup < ApplicationRecord
  # 工程を1つ進めたときの遷移先
  STAGE_TRANSITIONS = {
    "sown" => "germinating",
    "germinating" => "thinning",
    "thinning" => "pot_up_ready",
    "rooting_wait" => "rooted",
    "rooted" => "pot_up_ready"
  }.freeze

  # 生産方法（播種/挿し木）ごとに取り得る工程の一覧
  STAGES_BY_PROPAGATION_METHOD = {
    "seed" => %w[sown germinating thinning pot_up_ready],
    "cutting" => %w[rooting_wait rooted pot_up_ready]
  }.freeze

  belongs_to :production_lot
  belongs_to :location
  has_many :stocks,
           foreign_key: :source_nursery_group_id,
           inverse_of: :source_nursery_group,
           dependent: :restrict_with_error

  enum :stage, {
    sown: "sown",
    germinating: "germinating",
    thinning: "thinning",
    rooting_wait: "rooting_wait",
    rooted: "rooted",
    pot_up_ready: "pot_up_ready"
  }, validate: true

  enum :growing_method, {
    water: "water",
    soil: "soil"
  }, validate: true

  validates :stage_started_on, presence: true
  validates :quantity,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :stage_matches_propagation_method

  # 現在工程の次の工程（最終工程なら nil）
  def next_stage
    STAGE_TRANSITIONS[stage]
  end

  private

  # stageは生産方法（播種/挿し木）で許容される工程と一致していなければならない
  def stage_matches_propagation_method
    return unless production_lot&.propagation_method && stage

    allowed_stages = STAGES_BY_PROPAGATION_METHOD[production_lot.propagation_method]
    return if allowed_stages&.include?(stage)

    errors.add(:stage, :invalid)
  end
end
