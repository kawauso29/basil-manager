# == 役割
# 株に対して行った栽培作業を時系列で記録するモデル。
# 株の現在値ではなく、いつ何を行ったかという履歴を保持する。
#
# == カラム
# id          : 作業記録ID
# stock_id    : 対象の株ID
# action_type : 作業の種類
# memo        : 作業内容の補足
# recorded_at : 作業を行った日時
# created_at  : 登録日時
# updated_at  : 更新日時
class StockActionLog < ActiveRecord::Base
  belongs_to :stock
  belongs_to :from_location, class_name: "Location", optional: true
  belongs_to :to_location, class_name: "Location", optional: true

  HISTORY_MANAGED_ACTION_TYPES = %w[ moved status_changed quantity_changed ].freeze

  validates :action_type,  presence: true
  validates :quantity_before, :quantity_after,
            numericality: { only_integer: true, greater_than: 0 },
            if: -> { quantity_changed? && !legacy_history_log_without_details? }
  validates :status_before, :status_after,
            presence: true,
            inclusion: { in: Stock.statuses.keys },
            if: -> { status_changed? && !legacy_history_log_without_details? }
  validates :from_location, :to_location,
            presence: true,
            if: -> { moved? && !legacy_history_log_without_details? }

  enum :action_type, {
    seed_sown: "seed_sown",
    cutting_started: "cutting_started",
    water_started: "water_started",
    watered: "watered",
    fertilized: "fertilized",
    pinched: "pinched",
    pruned: "pruned",
    water_replaced: "water_replaced",
    harvested: "harvested",
    moved: "moved",
    status_changed: "status_changed",
    transplanted: "transplanted",
    quantity_changed: "quantity_changed"
  }, validate: true

  def history_managed?
    action_type.in?(HISTORY_MANAGED_ACTION_TYPES)
  end

  private

  def legacy_history_log_without_details?
    return false unless persisted? && !will_save_change_to_action_type?

    history_detail_values.all?(&:blank?)
  end

  def history_detail_values
    case action_type
    when "moved"
      [ from_location_id, to_location_id ]
    when "status_changed"
      [ status_before, status_after ]
    when "quantity_changed"
      [ quantity_before, quantity_after ]
    else
      []
    end
  end
end
