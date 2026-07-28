require "base64"
require "csv"
require "json"

module DataExport
  class CsvWriter
    COLUMNS = %w[
      record_type
      record_id
      record_role
      main_record_type
      main_record_id
      association_name
      attributes_json
      image_filename
      image_content_type
      image_byte_size
      image_data_url
    ].freeze

    RECORD_STRUCTURE = {
      Location => %i[location_observations].freeze,
      Plant => [].freeze,
      Stock => %i[stock_action_logs stock_observations].freeze
    }.freeze

    def self.write_to(stream)
      new(stream).write
    end

    def initialize(stream)
      @stream = stream
      @csv = CSV.new(stream)
    end

    def write
      csv << COLUMNS

      RECORD_STRUCTURE.each do |main_record_type, log_associations|
        main_record_type.find_each do |main_record|
          write_record(main_record, main_record:, record_role: "main")

          log_associations.each do |association_name|
            main_record.public_send(association_name).find_each do |log_record|
              write_record(
                log_record,
                main_record:,
                record_role: "log",
                association_name:
              )
            end
          end
        end
      end
    end

    private

    attr_reader :csv, :stream

    def write_record(record, main_record:, record_role:, association_name: nil)
      attachment = record.image if record.respond_to?(:image)
      row_context = {
        main_record:,
        record_role:,
        association_name:
      }
      return csv << row_for(record, **row_context) unless attachment&.attached?

      write_row_with_image(record, attachment.blob, **row_context)
    end

    def row_for(record, main_record:, record_role:, association_name:, blob: nil)
      [
        record.class.name,
        record.id,
        record_role,
        main_record.class.name,
        main_record.id,
        association_name,
        JSON.generate(record.attributes),
        blob&.filename&.to_s,
        blob&.content_type,
        blob&.byte_size,
        nil
      ]
    end

    def write_row_with_image(record, blob, **row_context)
      stream.write(CSV.generate_line(row_for(record, blob:, **row_context).first(COLUMNS.length - 1)).delete_suffix("\n"))
      stream.write(",")
      stream.write(
        CSV.generate_line([ "data:#{blob.content_type};base64," ]).delete_suffix("\n").delete_suffix('"')
      )
      write_base64(stream, blob)
      stream.write("\"\n")
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
