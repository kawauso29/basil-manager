class Admin::StockObservationsController < Admin::BaseController
  def index
    @stock_observations = StockObservation.all.order(:recorded_at).limit(30)
  end

  def new
    @stock_observation = StockObservation.new(recorded_at: Time.current)
    set_form_options
  end

  def create
    @stock_observation = StockObservation.new(stock_observation_params)
    if @stock_observation.save
      admin_create_success_message
      redirect_to admin_stock_observations_path
    else
      set_form_options
      admin_create_error_message(@stock_observation)
      render :new, status: :unprocessable_content
    end
  end

  def show
    @stock_observation = StockObservation.find(params[:id])
    set_stock_relation
  end

  def edit
    @stock_observation = StockObservation.find(params[:id])
    set_stock_relation
    set_form_options
  end

  def update
    @stock_observation = StockObservation.find(params[:id])
    if @stock_observation.update(stock_observation_params)
      admin_update_success_message(@stock_observation)
      redirect_to admin_stock_observation_path(@stock_observation)
    else
      # 基本ここには流れてこないはず
      admin_update_error_message(@stock_observation)
      set_stock_relation
      set_form_options
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @stock_observation = StockObservation.find(params[:id])
    if @stock_observation.destroy
      admin_destroy_success_message
      redirect_to admin_stock_observations_path
    else
      # 基本ここには流れてこないはず
      admin_destroy_error_message(@stock_observation)
      set_stock_relation
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_form_options
    @stock_data = Stock.active.pluck(:code, :id)
  end

  def set_stock_relation
    @stock = @stock_observation.stock
    @location = @stock.location
    @plant = @stock.plant
  end

  def stock_observation_params
    params.require(:stock_observation).permit(
      :stock_id,
      :height_cm,
      :memo,
      :recorded_at
    )
  end
end
