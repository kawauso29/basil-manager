require "base64"
require "csv"
require "json"

module DataExport
  class CsvWriter
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

    def self.write_to(stream)
      new(stream).write
    end

    def initialize(stream)
      @stream = stream
      @csv = CSV.new(stream)
    end

    def write
      csv << COLUMNS

      RECORD_TYPES.each do |record_type|
        record_type.find_each do |record|
          write_record(record)
        end
      end
    end

    private

    attr_reader :csv, :stream

    def write_record(record)
      attachment = record.image if record.respond_to?(:image)
      return csv << row_for(record) unless attachment&.attached?

      write_row_with_image(record, attachment.blob)
    end

    def row_for(record)
      [ record.class.name, record.id, JSON.generate(record.attributes), nil, nil, nil, nil ]
    end

    def write_row_with_image(record, blob)
      stream.write(CSV.generate_line(image_row_prefix(record, blob)).delete_suffix("\n"))
      stream.write(",")
      stream.write(
        CSV.generate_line([ "data:#{blob.content_type};base64," ]).delete_suffix("\n").delete_suffix('"')
      )
      write_base64(stream, blob)
      stream.write("\"\n")
    end

    def image_row_prefix(record, blob)
      [
        record.class.name,
        record.id,
        JSON.generate(record.attributes),
        blob.filename.to_s,
        blob.content_type,
        blob.byte_size
      ]
    end

    def write_base64(stream, blob)
      remainder = "".b

      blob.download do |chunk|
        data = remainder + chunk
        complete_byte_size = data.bytesize - (data.bytesize % 3)
        stream.write(Base64.strict_encode64(data.byteslice(0, complete_byte_size))) if complete_byte_size.positive?
        remainder = data.byteslice(complete_byte_size, data.bytesize - complete_byte_size) || "".b
      end

      stream.write(Base64.strict_encode64(remainder)) if remainder.present?
    end
  end
end
