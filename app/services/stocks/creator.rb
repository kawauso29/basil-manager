module Stocks
  class Creator
    attr_reader :plant, :plant_id, :location_id, :growing_method, :propagation_method, :quantity, :memo

    def self.call(plant_id:, location_id:, growing_method:, propagation_method: nil, quantity: 1, memo: nil)
      new(
          plant_id: plant_id,
          location_id: location_id,
          growing_method: growing_method,
          propagation_method: propagation_method,
          quantity: quantity,
          memo: memo
      ).call
    end

    def initialize(plant_id:, location_id:, growing_method:, propagation_method: nil, quantity: 1, memo: nil)
      @plant_id = plant_id
      @location_id = location_id
      @growing_method = growing_method
      @propagation_method = propagation_method
      @quantity = quantity.presence || 1
      @memo = memo

      @plant = load_plant(plant_id)
    end

    def call
      Stock.transaction do
        plant.with_lock do
          stock_number = next_stock_number
          update_plant_last_stock_number!(stock_number)
          stock = create_stock(stock_number)
          stock
        end
      end
    end

    private

    def load_plant(plant_id)
      plant = Plant.find(plant_id)
    end

    def next_stock_number
      plant.last_stock_number + 1
    end

    def stock_code(next_stock_number)
      prefix = plant.prefix
      "#{prefix}-#{next_stock_number}"
    end

    def create_stock(stock_number)
      stock = Stock.create!(
        plant_id: plant_id,
        location_id: location_id,
        code: stock_code(stock_number),
        status: :starting,
        growing_method: growing_method,
        propagation_method: propagation_method,
        quantity: quantity,
        memo: memo
      )
      stock
    end

    def update_plant_last_stock_number!(stock_number)
      plant.update!(last_stock_number: stock_number)
    end
  end
end
