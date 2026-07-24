module StockActionLogs
  class BulkWateringCreator
    class InvalidSelection < StandardError; end

    attr_reader :stock_ids, :recorded_at, :memo

    def self.call(stock_ids:, recorded_at:, memo:)
      new(
        stock_ids: stock_ids,
        recorded_at: recorded_at,
        memo: memo
      ).call
    end

    def initialize(stock_ids:, recorded_at:, memo:)
      @stock_ids = stock_ids
      @recorded_at = recorded_at
      @memo = memo
    end

    def call
      target_stock_ids = Array(stock_ids).compact_blank.map(&:to_i).uniq
      if target_stock_ids.blank?
        raise InvalidSelection, "対象の株を選択してください"
      end
      if recorded_at.blank?
        raise InvalidSelection, "記録日時を入力してください"
      end

      stocks = Stock.active.joins(:location).merge(Location.outdoor).where(id: target_stock_ids).order(:id)
      if stocks.length != target_stock_ids.length
        raise InvalidSelection, "屋外で育成中の株だけを選択してください"
      end

      StockActionLog.transaction do
        created_logs = []
        stocks.each do |stock|
          created_logs << stock.stock_action_logs.create!(
            action_type: :watered,
            recorded_at: recorded_at,
            memo: memo
          )
        end
        created_logs
      end
    end
  end
end
