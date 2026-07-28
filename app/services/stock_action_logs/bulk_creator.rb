module StockActionLogs
  class BulkCreator
    class InvalidSelection < StandardError; end

    attr_reader :stock_ids, :environment, :location_ids, :action_type, :recorded_at, :memo

    def self.call(stock_ids:, environment:, location_ids:, action_type:, recorded_at:, memo:)
      new(
        stock_ids: stock_ids,
        environment: environment,
        location_ids: location_ids,
        action_type: action_type,
        recorded_at: recorded_at,
        memo: memo
      ).call
    end

    def initialize(stock_ids:, environment:, location_ids:, action_type:, recorded_at:, memo:)
      @stock_ids = stock_ids
      @environment = environment
      @location_ids = location_ids
      @action_type = action_type
      @recorded_at = recorded_at
      @memo = memo
    end

    def call
      target_stock_ids = Array(stock_ids).compact_blank.map(&:to_i).uniq
      raise InvalidSelection, "対象の株を選択してください" if target_stock_ids.blank?
      unless environment.to_s.in?(Location.environments.keys)
        raise InvalidSelection, "屋内または屋外を選択してください"
      end
      validate_locations!
      unless action_type.to_s.in?(available_action_types)
        raise InvalidSelection, "一括記録できるアクション種別を選択してください"
      end
      raise InvalidSelection, "記録日時を入力してください" if recorded_at.blank?

      stocks = target_stocks.where(id: target_stock_ids).order(:id)
      if stocks.length != target_stock_ids.length
        raise InvalidSelection, "選択した条件に一致する育成中の株だけを選択してください"
      end

      StockActionLog.transaction do
        stocks.map do |stock|
          stock.stock_action_logs.create!(
            action_type: action_type,
            recorded_at: recorded_at,
            memo: memo
          )
        end
      end
    end

    private

    def validate_locations!
      return if target_location_ids.blank?
      valid_location_count = Location.where(
        id: target_location_ids,
        environment: environment
      ).count
      return if valid_location_count == target_location_ids.length

      raise InvalidSelection, "選択した環境のロケーションだけを指定してください"
    end

    def target_stocks
      stocks = Stock.active.joins(:location).merge(Location.where(environment: environment))
      return stocks if target_location_ids.blank?

      stocks.where(location_id: target_location_ids)
    end

    def target_location_ids
      @target_location_ids ||= Array(location_ids).compact_blank.map(&:to_i).uniq
    end

    def available_action_types
      StockActionLog.action_types.keys - StockActionLog::HISTORY_MANAGED_ACTION_TYPES
    end
  end
end
