class Admin::StocksController < Admin::BaseController
  include Admin::ImageAttachment

  def index
    @stock_filters = stock_filter_params
    @environment_filter_options = Location.environments_i18n.map { |key, label| [ label, key ] }
    @location_filter_options = Location.order(:name).map do |location|
      [ "#{location.name}（#{location.environment_i18n}）", location.id ]
    end
    @plant_filter_options = Plant.order(:name).pluck(:name, :id)
    @status_filter_options = Stock.statuses_i18n.map { |key, label| [ label, key ] }

    stocks = Stock.active
    if Location.environments.key?(@stock_filters[:environment])
      stocks = stocks.joins(:location).where(locations: { environment: @stock_filters[:environment] })
    end
    stocks = stocks.where(location_id: @stock_filters[:location_id]) if @stock_filters[:location_id].present?
    stocks = stocks.where(plant_id: @stock_filters[:plant_id]) if @stock_filters[:plant_id].present?
    stocks = stocks.where(status: @stock_filters[:status]) if Stock.statuses.key?(@stock_filters[:status])

    @stocks = stocks.includes(:plant, :location, image_attachment: :blob).order(id: :asc).load
    @stock_summary = Admin::StockSummaryPresenter.call(@stocks)
  end

  def new
    set_form_data_for_new
    @stock = Stock.new
  end

  def create
    @stock = Stocks::Creator.call(**create_stock_hash)
    attach_resized_image(@stock, create_stock_params[:image])
    admin_create_success_message
    redirect_to admin_stock_path(@stock)

  # モデルvalideteエラーブロック
  rescue ActiveRecord::RecordInvalid => e
    has_error_instance = e.record
    @stock = has_error_instance
    set_form_data_for_new
    admin_create_error_message(@stock)
    render :new, status: :unprocessable_content

  # record missing エラーブロック - 基本的にはここは流れない
  rescue ActiveRecord::RecordNotFound
    set_form_data_for_new
    @stock = Stock.new
    admin_flash_now_alert("作成に失敗しました。植物が見つかりません")
    render :new, status: :unprocessable_content
  end

  def show
    @stock = Stock.find(params[:id])
    set_record_navigation(@stock)
    set_show_data
  end

  def edit
    @stock = Stock.find(params[:id])
    set_record_navigation(@stock)
    set_form_data
  end

  def update
    @stock = Stock.find(params[:id])
    _params = stock_params
    location_changed = _params.key?(:location_id) && _params[:location_id].to_s != @stock.location_id.to_s
    status_changed = _params.key?(:status) && _params[:status] != @stock.status

    Stock.transaction do
      @stock.assign_attributes(_params.except(:image, :history_memo, :location_id, :status))
      attach_resized_image(@stock, _params[:image])
      @stock.save!
      @stock.move_to!(location_id: _params[:location_id], memo: _params[:history_memo]) if location_changed
      @stock.change_status!(status: _params[:status], memo: _params[:history_memo]) if status_changed
    end

    admin_update_success_message(@stock)
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid => e
    @stock = e.record
    set_record_navigation(@stock)
    admin_update_error_message(@stock)
    set_form_data
    render :edit, status: :unprocessable_content
  end

  def change_quantity
    @stock = Stock.find(params[:id])
    _params = quantity_change_params
    @stock.change_quantity!(
      quantity: _params[:quantity],
      memo: _params[:memo]
    )
    admin_update_success_message(@stock)
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid => e
    admin_flash_now_alert("数量変更に失敗しました #{e.record.errors.full_messages.join(', ')}")
    render :edit_quantity, status: :unprocessable_content
  end

  def edit_quantity
    @stock = Stock.find(params[:id])
  end

  def destroy
    @stock = Stock.find(params[:id])
    if @stock.destroy
      admin_destroy_success_message
      redirect_to admin_stocks_path
    else
      # 基本ここには流れてこないはず
      set_record_navigation(@stock)
      admin_destroy_error_message(@stock)
      set_show_data
      render :show, status: :unprocessable_content
    end
  end

  private

  def stock_filter_params
    params.permit(:environment, :location_id, :plant_id, :status)
  end

  def set_form_data_for_new
    @location_data = Location.pluck(:name, :id)
    @plant_data= Plant.pluck(:name, :id)
    @growing_method_data = Stock.growing_methods_i18n.map { |key, name| [ name, key ] }
    @propagation_method_data = Stock.propagation_methods_i18n.map { |key, name| [ name, key ] }
  end

  def set_form_data
    @location_data = Location.pluck(:name, :id)
    @plant_data= Plant.pluck(:name, :id)
    @growing_method_data = Stock.growing_methods_i18n.map { |key, name| [ name, key ] }
    @propagation_method_data = Stock.propagation_methods_i18n.map { |key, name| [ name, key ] }
    @status_data = Stock.statuses_i18n.map { |key, name| [ name, key ] }
    @completion_reason_data = Stock.completion_reasons_i18n.map { |key, name| [ name, key ] }
  end

  def stock_params
    params.require(:stock).permit(
      :plant_id,
      :location_id,
      :code,
      :status,
      :growing_method,
      :propagation_method,
      :completion_reason,
      :completed_at,
      :memo,
      :history_memo,
      :label,
      :image
    )
  end

  def create_stock_params
    params.require(:stock).permit(
      :plant_id,
      :location_id,
      :growing_method,
      :propagation_method,
      :quantity,
      :label,
      :memo,
      :image
    )
  end

  def create_stock_hash
    _params = create_stock_params
    {
      plant_id: _params[:plant_id],
      location_id: _params[:location_id],
      growing_method: _params[:growing_method],
      propagation_method: _params[:propagation_method],
      quantity: _params[:quantity],
      label: _params[:label],
      memo: _params[:memo]
    }
  end

  def quantity_change_params
    params.require(:stock_quantity).permit(:quantity, :memo)
  end

  def set_show_data
    action_logs = @stock.stock_action_logs.to_a
    observations = @stock.stock_observations.to_a
    @stock_logs = Admin::StockLogsPresenter.call(action_logs, observations)
    @stock_activity_summary = Admin::StockActivitySummaryPresenter.call(
      action_logs: action_logs,
      observations: observations,
    )
  end
end
