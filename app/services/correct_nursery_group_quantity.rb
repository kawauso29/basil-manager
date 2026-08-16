class CorrectNurseryGroupQuantity
  def self.call(nursery_group:, quantity:)
    nursery_group.with_lock do
      nursery_group.update!(quantity: quantity)
      nursery_group
    end
  end
end
