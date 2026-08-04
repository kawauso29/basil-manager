require "tempfile"

class Admin::DataExportsController < Admin::BaseController
  include ActionController::Live

  def show
    send_stream(
      filename: "basil-manager-data-#{Date.current.iso8601}.zip",
      type: "application/zip",
      disposition: "attachment"
    ) { |stream| write_archive_to(stream) }
  end

  private

  def write_archive_to(stream)
    Tempfile.create([ "basil-manager-data-", ".zip" ], binmode: true) do |file|
      DataExport::ZipWriter.write_to(file.path)
      file.rewind

      while (chunk = file.read(64 * 1024))
        stream.write(chunk)
      end
    end
  end
end
