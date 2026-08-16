class AdvanceNurseryGroup
  def self.call(nursery_group:, quantity:, recorded_on:)
    new(nursery_group, quantity, recorded_on).call
  end

  def initialize(nursery_group, quantity, recorded_on)
    @nursery_group = nursery_group
    @quantity = quantity
    @recorded_on = recorded_on
  end

  def call
    nursery_group.with_lock do
      validate_advance!
      return advance_entire_group! if quantity == nursery_group.quantity

      split_group!
    end
  end

  private

  attr_reader :nursery_group, :quantity, :recorded_on

  def validate_advance!
    unless nursery_group.next_stage
      nursery_group.errors.add(:stage, :invalid)
      raise ActiveRecord::RecordInvalid, nursery_group
    end
    return if quantity.positive? && quantity <= nursery_group.quantity

    nursery_group.errors.add(:quantity, :invalid)
    raise ActiveRecord::RecordInvalid, nursery_group
  end

  def advance_entire_group!
    nursery_group.update!(
      stage: nursery_group.next_stage,
      stage_started_on: recorded_on
    )
    nursery_group
  end

  def split_group!
    nursery_group.update!(quantity: nursery_group.quantity - quantity)
    nursery_group.production_lot.nursery_groups.create!(
      location: nursery_group.location,
      stage: nursery_group.next_stage,
      growing_method: nursery_group.growing_method,
      container_type: nursery_group.container_type,
      quantity: quantity,
      stage_started_on: recorded_on,
      memo: nursery_group.memo
    )
  end
end
