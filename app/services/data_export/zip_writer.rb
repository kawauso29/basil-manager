require "csv"
require "json"
require "zip"

module DataExport
  class ZipWriter
    CSV_COLUMNS = %w[
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
      image_path
    ].freeze

    RECORD_STRUCTURE = {
      Plant => [].freeze,
      Location => [].freeze,
      ProductionLot => [].freeze,
      NurseryGroup => [].freeze,
      Stock => %i[stock_observations].freeze
    }.freeze

    IMAGE_RECORD_TYPES = [ Plant, Location, StockObservation ].freeze

    def self.write_to(path)
      new(path).write
    end

    def initialize(path)
      @path = path
    end

    def write
      images = []

      Zip::OutputStream.open(path) do |archive|
        write_csv(archive, images)
        write_images(archive, images)
      end
    end

    private

    attr_reader :path

    def write_csv(archive, images)
      archive.put_next_entry("data.csv")
      csv = CSV.new(archive)
      csv << CSV_COLUMNS

      each_record do |record, context|
        blob = attached_blob(record)
        path = image_path(record, blob, **context) if blob
        images << [ path, blob ] if blob
        csv << csv_row(record, blob, path, **context)
      end
    end

    def write_images(archive, images)
      images.each do |image_path, blob|
        archive.put_next_entry(image_path)
        blob.download { |chunk| archive.write(chunk) }
      end
    end

    def each_record
      RECORD_STRUCTURE.each do |main_record_type, log_associations|
        main_record_type.find_each do |main_record|
          yield main_record, {
            main_record: main_record,
            record_role: "main",
            association_name: nil
          }

          log_associations.each do |association_name|
            main_record.public_send(association_name).find_each do |log_record|
              yield log_record, {
                main_record: main_record,
                record_role: "log",
                association_name: association_name
              }
            end
          end
        end
      end
    end

    def csv_row(record, blob, image_path, main_record:, record_role:, association_name:)
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
        image_path
      ]
    end

    def attached_blob(record)
      return unless IMAGE_RECORD_TYPES.any? { |record_type| record.is_a?(record_type) }
      return unless record.respond_to?(:image)
      return unless record.image.attached?

      record.image.blob
    end

    def image_path(record, blob, main_record:, **)
      directory =
        case record
        when Location
          "images/locations/#{record.id}"
        when Plant
          "images/plants/#{record.id}"
        when StockObservation
          "images/stocks/#{main_record.id}/observations/#{record.id}"
        else
          raise ArgumentError, "Unsupported image record: #{record.class.name}"
        end

      "#{directory}/#{safe_filename(blob)}"
    end

    def safe_filename(blob)
      File.basename(blob.filename.to_s.tr("\\", "/"))
    end
  end
end
