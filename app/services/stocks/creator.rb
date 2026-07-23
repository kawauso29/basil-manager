module Stocks
  class Creator
    attr_reader :plant, :location, :growing_method, :propagation_method

    def self.call(plant:, location:, growing_method:, propagation_method:)
      new(
          plant: plant,
          location: location,
          growing_method: growing_method,
          propagation_method: propagation_method
      ).call
    end

    def initialize(plant:, location:, growing_method:, propagation_method:)
      @plant = plant
      @location = location
      @growing_method = growing_method
      @propagation_method = propagation_method
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

    def next_stock_number
      plant.last_stock_number + 1
    end

    def stock_code(next_stock_number)
      prefix = plant.prefix
      "#{prefix}-#{next_stock_number}"
    end

    def create_stock(stock_number)
      stock = Stock.create!(
        plant: plant,
        location: location,
        code: stock_code(stock_number),
        status: :starting,
        growing_method: growing_method,
        propagation_method: propagation_method
      )
      stock
    end

    def update_plant_last_stock_number!(stock_number)
      plant.update!(last_stock_number: stock_number)
    end

  end
end
