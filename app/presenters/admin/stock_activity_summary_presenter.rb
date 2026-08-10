class Admin::StockActivitySummaryPresenter
  attr_reader :latest_action,
              :last_watered_action,
              :last_fertilized_action,
              :latest_observation,

  def self.call(action_logs:, observations:)
    new(
      action_logs: action_logs,
      observations: observations,
    ).call
  end

  def initialize(action_logs:, observations:)
    @action_logs = action_logs.to_a
    @observations = observations.to_a
  end

  def call
    @latest_action = action_data(latest_record(@action_logs))
    @last_watered_action = action_data(latest_action_of_type("watered"))
    @last_fertilized_action = action_data(latest_action_of_type("fertilized"))
    @latest_observation = observation_data(latest_record(@observations))
    self
  end

  private

  def latest_action_of_type(action_type)
    latest_record(@action_logs.select { |log| log.action_type == action_type })
  end

  def latest_record(records)
    records.max_by { |record| record.recorded_at || record.created_at }
  end

  def action_data(action)
    return if action.nil?

    {
      label: action.action_type_i18n,
      recorded_at: recorded_at_label(action)
    }
  end

  def observation_data(observation)
    return if observation.nil?

    {
      height_cm: observation.height_cm,
      recorded_at: recorded_at_label(observation)
    }
  end

  def recorded_at_label(record)
    return "日時未設定" if record.recorded_at.nil?

    record.recorded_at.strftime("%Y/%m/%d %H:%M")
  end
end
