class StartProduction
  def self.call(plant_id:, propagation_method:, started_on:, initial_quantity:, location_id:,
                growing_method:, container_type: nil, source_stock_id: nil, memo: nil)
    ProductionLot.transaction do
      lot = ProductionLot.create!(
        plant_id: plant_id,
        propagation_method: propagation_method,
        started_on: started_on,
        initial_quantity: initial_quantity,
        source_stock_id: source_stock_id,
        memo: memo
      )
      lot.nursery_groups.create!(
        location_id: location_id,
        stage: lot.initial_stage,
        growing_method: growing_method,
        container_type: container_type,
        quantity: initial_quantity,
        stage_started_on: started_on
      )
      lot
    end
  end
end
