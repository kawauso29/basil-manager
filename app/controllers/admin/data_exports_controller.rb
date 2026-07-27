class Admin::DataExportsController < Admin::BaseController
  include ActionController::Live

  def show
    send_stream(
      filename: "basil-manager-data-#{Date.current.iso8601}.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
    ) { |stream| DataExport::CsvWriter.write_to(stream) }
  end
end
