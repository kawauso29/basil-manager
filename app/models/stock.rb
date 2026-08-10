# == 役割
# 同じ条件でまとめて扱う株の管理単位を管理するモデル。
# 管理単位内の数量、現在の状態、栽培方法、増殖方法、管理場所の関係を保持する。
#
# == カラム
# id                 : 株ID
# plant_id           : 植物ID
# location_id        : 現在の管理場所ID
# code               : 株を識別する管理コード
# label              : 画面上の表示名
# public_token       : 外部公開用トークン
# status             : 現在の管理状態
# growing_method     : 栽培方法
# propagation_method : 増殖方法
# quantity           : 管理単位に含まれる株数
# memo               : 管理単位についてのメモ
# completion_reason  : 育成完了理由
# completed_at       : 育成完了日時
# created_at         : 作成日時
# updated_at         : 更新日時

class Stock < ActiveRecord::Base
  has_secure_token :public_token
  has_one_attached :image do |attachable|
    attachable.variant :icon_thumb, resize_to_limit: [ 100, 100 ], preprocessed: true
    attachable.variant :main_thumb, resize_to_limit: [ 300, 300 ], preprocessed: true
  end

  belongs_to :plant
  belongs_to :location

  has_many :stock_action_logs, dependent: :destroy
  has_many :stock_observations, dependent: :destroy

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
    seeding_tray: "seeding_tray",
    other: "other"
  }, validate: true

  enum :propagation_method, {
    cutting_soil: "cutting_soil",
    cutting_water: "cutting_water",
    seed: "seed"
  }, validate: { allow_blank: true }

  normalizes :propagation_method, with: ->(value) { value.presence }

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  #######################
  # scope
  #######################
  scope :active, -> { where(completed_at: nil) }

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

  def display_name
    [ label.presence, code ].compact.join(" / ")
  end

  def change_quantity!(quantity:, memo: nil, recorded_at: Time.current)
    with_lock do
      previous_quantity = self.quantity
      self.quantity = quantity

      if self.quantity == previous_quantity
        errors.add(:quantity, :unchanged)
        raise ActiveRecord::RecordInvalid, self
      end

      save!
      stock_action_logs.create!(
        action_type: :quantity_changed,
        quantity_before: previous_quantity,
        quantity_after: self.quantity,
        memo: quantity_change_log_memo(previous_quantity, self.quantity, memo),
        recorded_at: recorded_at
      )
    end
  end

  def move_to!(location_id:, memo: nil, recorded_at: Time.current)
    with_lock do
      target_location = Location.find_by(id: location_id)
      unless target_location
        errors.add(:location, :required)
        raise ActiveRecord::RecordInvalid, self
      end

      previous_location_id = self.location_id
      if target_location.id == previous_location_id
        errors.add(:location_id, :unchanged)
        raise ActiveRecord::RecordInvalid, self
      end

      self.location = target_location
      save!
      stock_action_logs.create!(
        action_type: :moved,
        from_location_id: previous_location_id,
        to_location_id: target_location.id,
        memo: memo,
        recorded_at: recorded_at
      )
    end
  end

  def change_status!(status:, memo: nil, recorded_at: Time.current)
    with_lock do
      previous_status = self.status
      self.status = status

      if self.status == previous_status
        errors.add(:status, :unchanged)
        raise ActiveRecord::RecordInvalid, self
      end

      save!
      stock_action_logs.create!(
        action_type: :status_changed,
        status_before: previous_status,
        status_after: self.status,
        memo: memo,
        recorded_at: recorded_at
      )
    end
  end

  private

  def quantity_change_log_memo(previous_quantity, new_quantity, memo)
    change_description = "#{previous_quantity}株 → #{new_quantity}株"
    return change_description if memo.blank?

    "#{change_description}（#{memo.strip}）"
  end
end
