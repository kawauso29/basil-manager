# bin/rails runner "load 'db/data/20260815_reset_all_business_data.rb'"

module DataScripts
  class ResetAllBusinessData20260815
    CONFIRMATION = "DELETE_ALL_BASIL_MANAGER_DATA".freeze
    PRODUCTION_CONFIRMATION = "DELETE_ALL_BASIL_MANAGER_PRODUCTION_DATA".freeze

    BUSINESS_TABLES = %w[
      plants
      locations
      production_lots
      nursery_groups
      stocks
      stock_observations
      stock_action_logs
    ].freeze

    DELETE_ORDER = %w[
      stock_observations
      stock_action_logs
      stocks
      nursery_groups
      production_lots
      locations
      plants
    ].freeze

    ACTIVE_STORAGE_TABLES = %w[
      active_storage_attachments
      active_storage_variant_records
      active_storage_blobs
    ].freeze

    def run
      print_counts
      confirm!
      delete_all
      puts "全業務データとActive Storageの画像実体を削除しました。"
    end

    private

    def print_counts
      puts "削除対象件数 (#{Rails.env}):"
      (BUSINESS_TABLES + ACTIVE_STORAGE_TABLES).each do |table_name|
        puts format("  %-34s %d", table_name, count(table_name))
      end
    end

    def confirm!
      unless ENV["CONFIRM"] == CONFIRMATION
        abort <<~MESSAGE
          中止しました。このスクリプトはバックアップを作成しません。
          ZIPエクスポートはAIへの本番データ提供用であり、復元用バックアップではありません。
          実行するには CONFIRM=#{CONFIRMATION} を指定してください。
        MESSAGE
      end

      return unless Rails.env.production?
      return if ENV["ALLOW_PRODUCTION_RESET"] == PRODUCTION_CONFIRMATION

      abort <<~MESSAGE
        production環境での実行を中止しました。
        追加で ALLOW_PRODUCTION_RESET=#{PRODUCTION_CONFIRMATION} を指定してください。
      MESSAGE
    end

    def delete_all
      blobs = load_blobs

      connection.transaction do
        break_source_stock_cycle
        delete_table("active_storage_attachments")
        delete_table("active_storage_variant_records")
        DELETE_ORDER.each { |table_name| delete_table(table_name) }
      end

      purge_blobs(blobs)
    end

    def connection
      ApplicationRecord.connection
    end

    def load_blobs
      return [] unless connection.data_source_exists?("active_storage_blobs")

      ActiveStorage::Blob.all.load.to_a
    end

    def count(table_name)
      return 0 unless connection.data_source_exists?(table_name)

      connection.select_value(<<~SQL.squish).to_i
        SELECT COUNT(*)
        FROM #{connection.quote_table_name(table_name)}
      SQL
    end

    def delete_table(table_name)
      return unless connection.data_source_exists?(table_name)

      connection.delete(<<~SQL.squish)
        DELETE FROM #{connection.quote_table_name(table_name)}
      SQL
    end

    def break_source_stock_cycle
      return unless connection.data_source_exists?("production_lots")
      return unless connection.column_exists?("production_lots", "source_stock_id")

      connection.update(<<~SQL.squish)
        UPDATE #{connection.quote_table_name("production_lots")}
        SET #{connection.quote_column_name("source_stock_id")} = NULL
      SQL
    end

    def purge_blobs(blobs)
      blobs.each do |blob|
        # ActiveStorage::Blob#purgeはDB行を先に削除する。実体を先に削除することで、
        # ストレージ障害時にBlob行を残し、このスクリプトを安全に再実行できるようにする。
        blob.delete
        blob.destroy!
      end
    end
  end
end

DataScripts::ResetAllBusinessData20260815.new.run
