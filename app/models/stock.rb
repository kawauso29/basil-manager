# == 役割
# 鉢上げによって個体管理へ切り替えた株、または直接登録した株を管理するモデル。
# 現在工程、現在地、販売可能日、管理完了を保持する。
class Stock < ApplicationRecord
  # 工程を1つ進めたときの遷移先
  STAGE_TRANSITIONS = {
    "acclimating" => "growing"
  }.freeze

  has_secure_token :public_token

  belongs_to :plant
  belongs_to :location
  belongs_to :source_nursery_group,
             class_name: "NurseryGroup",
             optional: true,
             inverse_of: :stocks

  has_one :production_lot, through: :source_nursery_group
  has_many :stock_observations, dependent: :restrict_with_error
  has_many :sourced_production_lots,
           class_name: "ProductionLot",
           foreign_key: :source_stock_id,
           inverse_of: :source_stock,
           dependent: :restrict_with_error

  enum :stage, {
    acclimating: "acclimating",
    growing: "growing"
  }, validate: true

  enum :completion_reason, {
    cultivation_ended: "cultivation_ended",
    dead: "dead",
    transferred: "transferred"
  }, validate: { allow_blank: true }

  # 購入者向け公開ページで育て方を出し分けるための商品形態
  enum :product_type, {
    hydro: "hydro",
    soil: "soil"
  }, validate: { allow_blank: true }

  validates :stage_started_on, presence: true
  validates :potted_on, presence: true, if: :source_nursery_group_id?
  validates :completion_reason, presence: true, if: :completed_at?
  validates :completed_at, presence: true, if: -> { completion_reason.present? }
  # 育て方を出せない公開ページを作らないため、公開する株には商品形態を必須とする
  validates :product_type, presence: true, if: :published_at?
  validate :source_nursery_group_plant_matches

  scope :active, -> { where(completed_at: nil) }
  scope :sale_ready, -> { active.where.not(sale_ready_on: nil) }
  # 公開ページに出せる株。管理完了後も購入者がページを開けるよう完了は除外しない
  scope :published, -> { where.not(published_at: nil) }

  def self.register_direct!(plant_id:, location_id:, stage:, stage_started_on:, potted_on: nil, memo: nil)
    create!(
      plant_id: plant_id,
      location_id: location_id,
      stage: stage,
      stage_started_on: stage_started_on,
      potted_on: potted_on,
      memo: memo
    )
  end

  def display_name
    "ST-#{id}"
  end

  def latest_height_observation
    stock_observations.where.not(height_cm: nil).order(recorded_at: :desc, id: :desc).first
  end

  def latest_height_cm
    latest_height_observation&.height_cm
  end

  def sale_ready?
    completed_at.nil? && sale_ready_on.present?
  end

  def advance_stage!(stage_started_on:)
    with_lock do
      ensure_active!
      next_stage = STAGE_TRANSITIONS[stage]
      unless next_stage
        errors.add(:stage, :invalid)
        raise ActiveRecord::RecordInvalid, self
      end

      update!(stage: next_stage, stage_started_on: stage_started_on)
      self
    end
  end

  def mark_sale_ready!(on:)
    with_lock do
      ensure_active!
      if on.blank?
        errors.add(:sale_ready_on, :blank)
        raise ActiveRecord::RecordInvalid, self
      end
      unless growing?
        errors.add(:stage, :invalid)
        raise ActiveRecord::RecordInvalid, self
      end

      update!(sale_ready_on: on)
      self
    end
  end

  def revoke_sale_ready!
    with_lock do
      ensure_active!
      update!(sale_ready_on: nil)
      self
    end
  end

  def complete!(reason:, at:)
    with_lock do
      ensure_active!
      update!(completion_reason: reason, completed_at: at)
      self
    end
  end

  private

  def ensure_active!
    return unless completed_at?

    errors.add(:completed_at, :invalid)
    raise ActiveRecord::RecordInvalid, self
  end

  def source_nursery_group_plant_matches
    return unless source_nursery_group && plant
    return if source_nursery_group.production_lot.plant_id == plant_id

    errors.add(:plant, :invalid)
  end
end
