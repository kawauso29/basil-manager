class ProductionLot < ApplicationRecord
  belongs_to :plant
  belongs_to :source_stock,
             class_name: "Stock",
             optional: true,
             inverse_of: :sourced_production_lots

  has_many :nursery_groups, dependent: :restrict_with_error
  has_many :stocks, through: :nursery_groups

  enum :propagation_method, {
    seed: "seed",
    cutting: "cutting"
  }, validate: true

  validates :started_on, presence: true
  validates :initial_quantity,
            numericality: { only_integer: true, greater_than: 0 }
  validate :source_stock_plant_matches

  def initial_stage
    seed? ? "sown" : "rooting_wait"
  end

  private

  def source_stock_plant_matches
    return unless source_stock && plant
    return if source_stock.plant_id == plant_id

    errors.add(:source_stock, :invalid)
  end
end
