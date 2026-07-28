class Admin::StocksController < Admin::BaseController
  include Admin::ImageAttachment

  def index
    @stocks = Stock.active.order(id: :asc)
  end

  def new
    set_form_data_for_new
    @stock = Stock.new
  end

  def create
    @stock = Stocks::Creator.call(**create_stock_hash)
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
    set_stock_logs
  end

  def edit
    @stock = Stock.find(params[:id])
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
    set_stock_logs
    admin_flash_now_alert("数量変更に失敗しました #{e.record.errors.full_messages.join(', ')}")
    render :show, status: :unprocessable_content
  end

  def destroy
    @stock = Stock.find(params[:id])
    if @stock.destroy
      admin_destroy_success_message
      redirect_to admin_stocks_path
    else
      # 基本ここには流れてこないはず
      admin_destroy_error_message(@stock)
      @stock_logs = Admin::StockLogsPresenter.call(@stock.stock_action_logs, @stock.stock_observations)
      render :show, status: :unprocessable_content
    end
  end

  private

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
    @parent_data = Stock.active.where.not(id: params[:id]).map do |stock|
      [ stock.display_name, stock.id ]
    end
  end

  def stock_params
    params.require(:stock).permit(
      :plant_id,
      :location_id,
      :parent_stock_id,
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
      :memo
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

  def set_stock_logs
    @stock_logs = Admin::StockLogsPresenter.call(@stock.stock_action_logs, @stock.stock_observations)
  end
end
