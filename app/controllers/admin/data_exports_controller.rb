require "tempfile"

class Admin::DataExportsController < Admin::BaseController
  # send_streamによるレスポンスの逐次送信を有効にする。
  # 生成済みZIPを64KBずつ送り、ZIP全体をレスポンス用メモリへ展開しない。
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
