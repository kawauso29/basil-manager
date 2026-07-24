class Admin::StockLogsPresenter

  def self.call(action_logs, observation_logs)
    new(
      action_logs,
      observation_logs
    ).call
  end

  def initialize(action_logs, observation_logs)
    @action_logs = action_logs
    @observation_logs = observation_logs
  end

  def call
    build_log_data
    .sort_by { |log| log[:recorded_at] }
    .map { |log| format_log(log) }
  end

  private

  def build_log_data
    action_log_data + observation_log_data
  end

  def action_log_data
    @action_logs.map do |log|
      log_unit(
        log.recorded_at,
        log.action_type_i18n,
        nil,
        log.memo
      )
    end
  end

  def observation_log_data
    @observation_logs.map do |log|
      log_unit(
        log.recorded_at,
        "観察",
        "#{log.height_cm} cm",
        log.memo
      )
    end
  end

  def log_unit(recorded_at, label, data_value, memo)
    {
      recorded_at: recorded_at,
      label: label,
      data_value: data_value,
      memo: memo
    }
  end

  def format_log(log)
    log.merge(
      recorded_at: log[:recorded_at].strftime("%Y年%m月%d日%H時")
    )
  end
end