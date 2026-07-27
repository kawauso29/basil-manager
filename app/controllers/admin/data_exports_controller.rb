class Admin::DataExportsController < Admin::BaseController
  def show
    send_data(
      DataExport::CsvBuilder.call,
      filename: "basil-manager-ai-data-#{Date.current.iso8601}.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
    )
  end
end
