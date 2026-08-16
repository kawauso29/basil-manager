class NurseryGroup < ApplicationRecord
  STAGE_TRANSITIONS = {
    "sown" => "germinating",
    "germinating" => "thinning",
    "thinning" => "pot_up_ready",
    "rooting_wait" => "rooted",
    "rooted" => "pot_up_ready"
  }.freeze

  STAGES_BY_PROPAGATION_METHOD = {
    "seed" => %w[sown germinating thinning pot_up_ready],
    "cutting" => %w[rooting_wait rooted pot_up_ready]
  }.freeze

  belongs_to :production_lot
  belongs_to :location
  has_many :stocks,
           foreign_key: :source_nursery_group_id,
           inverse_of: :source_nursery_group,
           dependent: :restrict_with_error

  enum :stage, {
    sown: "sown",
    germinating: "germinating",
    thinning: "thinning",
    rooting_wait: "rooting_wait",
    rooted: "rooted",
    pot_up_ready: "pot_up_ready"
  }, validate: true

  enum :growing_method, {
    water: "water",
    soil: "soil"
  }, validate: true

  validates :stage_started_on, presence: true
  validates :quantity,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :stage_matches_propagation_method

  def next_stage
    STAGE_TRANSITIONS[stage]
  end

  private

  def stage_matches_propagation_method
    return unless production_lot&.propagation_method && stage

    allowed_stages = STAGES_BY_PROPAGATION_METHOD[production_lot.propagation_method]
    return if allowed_stages&.include?(stage)

    errors.add(:stage, :invalid)
  end
end
