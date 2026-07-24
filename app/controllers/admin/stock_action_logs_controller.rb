class Admin::StockActionLogsController < Admin::BaseController
  def index
    @stock_action_logs = StockActionLog.all.order(:recorded_at).limit(30)
  end

  def new
    @stock_action_log = StockActionLog.new(recorded_at: Time.current)
    set_form_options
  end

  def create
    @stock_action_log = StockActionLog.new(stock_action_log_params)
    if @stock_action_log.save
      admin_create_success_message
      redirect_to admin_stock_action_logs_path
    else
      set_form_options
      admin_create_error_message(@stock_action_log)
      render :new, status: :unprocessable_content
    end
  end

  def show
    @stock_action_log = StockActionLog.find(params[:id])
    set_stock_relation
  end

  def edit
    @stock_action_log = StockActionLog.find(params[:id])
    set_stock_relation
    set_form_options
  end

  def update
    @stock_action_log = StockActionLog.find(params[:id])
    if @stock_action_log.update(stock_action_log_params)
      admin_update_success_message(@stock_action_log)
      redirect_to admin_stock_action_log_path(@stock_action_log)
    else
      # 基本ここには流れてこないはず
      admin_update_error_message(@stock_action_log)
      set_stock_relation
      set_form_options
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @stock_action_log = StockActionLog.find(params[:id])
    if @stock_action_log.destroy
      admin_destroy_success_message
      redirect_to admin_stock_action_logs_path
    else
      # 基本ここには流れてこないはず
      admin_destroy_error_message(@stock_action_log)
      set_stock_relation
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_form_options
    @stock_data = Stock.active.pluck(:code, :id)
    @action_type_data = StockActionLog.action_types_i18n.map do |key, value|
      [value, key]
    end
  end

  def set_stock_relation
    @stock = @stock_action_log.stock
    @location = @stock.location
    @plant = @stock.plant
  end

  def stock_action_log_params
    params.require(:stock_action_log).permit(
      :stock_id,
      :action_type,
      :memo,
      :recorded_at
    )
  end
end
