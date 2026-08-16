class Admin::ProductionLotsController < Admin::BaseController
  def index
    @production_lots = ProductionLot.includes(:plant, :source_stock).order(id: :desc)
  end

  def show
    @production_lot = ProductionLot.includes(:plant, :source_stock).find(params[:id])
    set_record_navigation(@production_lot)
    @nursery_groups = @production_lot.nursery_groups.includes(:location).order(id: :asc)
    @stocks = @production_lot.stocks.includes(:plant, :location, source_nursery_group: :production_lot).order(id: :asc)
  end

  def new
    @form_values = {
      started_on: Date.current,
      initial_quantity: 1
    }
    set_form_options
  end

  def create
    @production_lot = StartProduction.call(**start_production_attributes)
    admin_create_success_message
    redirect_to admin_production_lot_path(@production_lot)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @form_values = start_production_params.to_h.symbolize_keys
    set_form_options
    admin_flash_now_alert("生産開始に失敗しました #{error_messages(e)}")
    render :new, status: :unprocessable_content
  end

  private

  def set_form_options
    @plant_options = Plant.order(:name).pluck(:name, :id)
    @location_options = Location.order(:name).pluck(:name, :id)
    @propagation_method_options = ProductionLot.propagation_methods_i18n.map do |value, label|
      [ label, value ]
    end
    @growing_method_options = NurseryGroup.growing_methods_i18n.map do |value, label|
      [ label, value ]
    end
    @source_stock_options = Stock.active.includes(:plant).order(:id).map do |stock|
      [ "ST-#{stock.id} / #{stock.plant.name}", stock.id ]
    end
  end

  def start_production_params
    params.require(:production).permit(
      :plant_id,
      :propagation_method,
      :started_on,
      :initial_quantity,
      :location_id,
      :growing_method,
      :container_type,
      :source_stock_id,
      :memo
    )
  end

  def start_production_attributes
    values = start_production_params
    {
      plant_id: values[:plant_id],
      propagation_method: values[:propagation_method],
      started_on: values[:started_on],
      initial_quantity: values[:initial_quantity],
      location_id: values[:location_id],
      growing_method: values[:growing_method],
      container_type: values[:container_type].presence,
      source_stock_id: values[:source_stock_id].presence,
      memo: values[:memo].presence
    }
  end

  def error_messages(error)
    return error.record.errors.full_messages.join(", ") if error.respond_to?(:record)

    error.message
  end
end
