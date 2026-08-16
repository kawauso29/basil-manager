class PotUpNurseryGroup
  def self.call(nursery_group:, quantity:, location_id:, potted_on:)
    new(nursery_group, quantity, location_id, potted_on).call
  end

  def initialize(nursery_group, quantity, location_id, potted_on)
    @nursery_group = nursery_group
    @quantity = quantity
    @location = Location.find(location_id)
    @potted_on = potted_on
  end

  def call
    nursery_group.with_lock do
      validate_pot_up!
      stocks = Array.new(quantity) { create_stock! }
      nursery_group.update!(quantity: nursery_group.quantity - quantity)
      stocks
    end
  end

  private

  attr_reader :nursery_group, :quantity, :location, :potted_on

  def validate_pot_up!
    unless nursery_group.pot_up_ready?
      nursery_group.errors.add(:stage, :invalid)
      raise ActiveRecord::RecordInvalid, nursery_group
    end
    return if quantity.positive? && quantity <= nursery_group.quantity

    nursery_group.errors.add(:quantity, :invalid)
    raise ActiveRecord::RecordInvalid, nursery_group
  end

  def create_stock!
    Stock.create!(
      plant: nursery_group.production_lot.plant,
      location: location,
      source_nursery_group: nursery_group,
      stage: :acclimating,
      stage_started_on: potted_on,
      potted_on: potted_on
    )
  end
end
