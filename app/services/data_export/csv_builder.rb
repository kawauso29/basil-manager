require "base64"
require "csv"
require "json"

module DataExport
  class CsvBuilder
    COLUMNS = %w[
      record_type
      record_id
      attributes_json
      image_filename
      image_content_type
      image_byte_size
      image_data_url
    ].freeze

    RECORD_TYPES = [
      Plant,
      Location,
      Stock,
      StockActionLog,
      StockObservation,
      LocationObservation
    ].freeze

    def self.call
      new.call
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << COLUMNS

        RECORD_TYPES.each do |record_type|
          record_type.find_each do |record|
            csv << row_for(record)
          end
        end
      end
    end

    private

    def row_for(record)
      [
        record.class.name,
        record.id,
        JSON.generate(record.attributes),
        *image_data_for(record)
      ]
    end

    def image_data_for(record)
      return [ nil, nil, nil, nil ] unless record.respond_to?(:image) && record.image.attached?

      blob = record.image.blob
      [
        blob.filename.to_s,
        blob.content_type,
        blob.byte_size,
        "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
      ]
    end
  end
end
