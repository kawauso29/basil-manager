class Admin::StocksController < Admin::BaseController
  def index
    @stocks = Stock.all
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
    @stock_logs = Admin::StockLogsPresenter.call(@stock.stock_action_logs, @stock.stock_observations)
  end

  def edit
    @stock = Stock.find(params[:id])
    set_form_data
  end

  def update
    @stock = Stock.find(params[:id])
    if @stock.update(stock_params)
      admin_update_success_message(@stock)
      redirect_to admin_stock_path(@stock)
    else
      admin_update_error_message(@stock)
      set_form_data
      render :edit, status: :unprocessable_content
    end
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
    @growing_method_data = Stock.growing_methods_i18n.map{|key,name| [name, key]}
    @propagation_method_data = Stock.propagation_methods_i18n.map{|key,name| [name, key]}
  end

  def set_form_data
    @location_data = Location.pluck(:name, :id)
    @plant_data= Plant.pluck(:name, :id)
    @growing_method_data = Stock.growing_methods_i18n.map{|key,name| [name, key]}
    @propagation_method_data = Stock.propagation_methods_i18n.map{|key,name| [name, key]}
    @status_data = Stock.statuses_i18n.map{|key,name| [name, key]}
    @completion_reason_data = Stock.completion_reasons_i18n.map{|key,name| [name, key]}
    @parent_data = Stock.active.where.not(id: params[:id]).pluck(:code, :id)
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
    )
  end

  def create_stock_hash
    _params = stock_params
    {
      plant_id:  _params[:plant_id],
      location_id:  _params[:location_id],
      growing_method:  _params[:growing_method],
      propagation_method:  _params[:propagation_method],
    }
  end
end
