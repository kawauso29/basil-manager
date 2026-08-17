class Admin::StocksController < Admin::BaseController
  before_action :set_stock, only: %i[
    show edit update advance_stage_form advance_stage sale_ready_form
    mark_sale_ready revoke_sale_ready complete_form complete
  ]

  def index
    @stock_filters = stock_filter_params
    set_filter_options

    stocks = Stock.all
    if Location.environments.key?(@stock_filters[:environment])
      stocks = stocks.joins(:location).where(locations: { environment: @stock_filters[:environment] })
    end
    stocks = stocks.where(location_id: @stock_filters[:location_id]) if @stock_filters[:location_id].present?
    stocks = stocks.where(plant_id: @stock_filters[:plant_id]) if @stock_filters[:plant_id].present?
    stocks = stocks.where(stage: @stock_filters[:stage]) if Stock.stages.key?(@stock_filters[:stage])
    stocks = filter_sale_ready(stocks)
    stocks = filter_completion(stocks)

    @stocks = stocks.includes(:plant, :location, :production_lot).order(id: :asc).load
  end

  def new
    @stock = Stock.new(stage_started_on: Date.current)
    set_form_options(include_stage: true)
  end

  def create
    @stock = Stock.register_direct!(**create_stock_attributes)
    admin_create_success_message
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @stock = e.record if e.respond_to?(:record) && e.record.is_a?(Stock)
    @stock ||= Stock.new(create_stock_params)
    set_form_options(include_stage: true)
    admin_flash_now_alert("作成に失敗しました #{error_messages(e)}")
    render :new, status: :unprocessable_content
  end

  def show
    set_record_navigation(@stock)
    @stock_observations = @stock.stock_observations.order(recorded_at: :desc, id: :desc)
    @latest_height_observation = @stock_observations.where.not(height_cm: nil).first
  end

  def edit
    set_record_navigation(@stock)
    set_form_options
  end

  def update
    if @stock.update(stock_params)
      admin_update_success_message(@stock)
      redirect_to admin_stock_path(@stock)
    else
      set_record_navigation(@stock)
      set_form_options
      admin_update_error_message(@stock)
      render :edit, status: :unprocessable_content
    end
  end

  def advance_stage_form
    @stage_started_on = Date.current
  end

  # 現在工程を次工程へ進める
  def advance_stage
    @stock.advance_stage!(stage_started_on: advance_stage_params[:stage_started_on])
    admin_flash_notice("生産工程を進めました")
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @stage_started_on = advance_stage_params[:stage_started_on]
    admin_flash_now_alert("工程変更に失敗しました #{error_messages(e)}")
    render :advance_stage_form, status: :unprocessable_content
  end

  def sale_ready_form
    @sale_ready_on = Date.current
  end

  # 販売可能日を設定する
  def mark_sale_ready
    @stock.mark_sale_ready!(on: sale_ready_params[:sale_ready_on])
    admin_flash_notice("販売可能にしました")
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @sale_ready_on = sale_ready_params[:sale_ready_on]
    admin_flash_now_alert("販売可能日の設定に失敗しました #{error_messages(e)}")
    render :sale_ready_form, status: :unprocessable_content
  end

  # 販売可能設定を取り消す
  def revoke_sale_ready
    @stock.revoke_sale_ready!
    admin_flash_notice("販売可能を解除しました")
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    redirect_to admin_stock_path(@stock), alert: "販売可能の解除に失敗しました #{error_messages(e)}"
  end

  def complete_form
    @completed_at = Time.current
    set_completion_reason_options
  end

  # 栽培管理を完了する（完了理由と日時を記録し、以後の工程操作を止める）
  def complete
    @stock.complete!(reason: complete_params[:completion_reason], at: complete_params[:completed_at])
    admin_flash_notice("管理を完了しました")
    redirect_to admin_stock_path(@stock)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @completed_at = complete_params[:completed_at]
    set_completion_reason_options
    admin_flash_now_alert("管理完了に失敗しました #{error_messages(e)}")
    render :complete_form, status: :unprocessable_content
  end

  private

  def set_stock
    @stock = Stock.includes(:plant, :location, :production_lot, :source_nursery_group).find(params[:id])
  end

  def set_filter_options
    @environment_filter_options = Location.environments_i18n.map { |key, label| [ label, key ] }
    @location_filter_options = Location.order(:name).map do |location|
      [ "#{location.name}（#{location.environment_i18n}）", location.id ]
    end
    @plant_filter_options = Plant.order(:name).pluck(:name, :id)
    @stage_filter_options = Stock.stages_i18n.map { |key, label| [ label, key ] }
  end

  def set_form_options(include_stage: false)
    @location_options = Location.order(:name).pluck(:name, :id)
    @plant_options = Plant.order(:name).pluck(:name, :id)
    @stage_options = Stock.stages_i18n.map { |key, label| [ label, key ] } if include_stage
  end

  def set_completion_reason_options
    @completion_reason_options = Stock.completion_reasons_i18n.map do |value, label|
      [ label, value ]
    end
  end

  def filter_sale_ready(stocks)
    case @stock_filters[:sale_ready]
    when "ready"
      stocks.where(id: Stock.sale_ready.select(:id))
    when "not_ready"
      stocks.where.not(id: Stock.sale_ready.select(:id))
    else
      stocks
    end
  end

  def filter_completion(stocks)
    case @stock_filters[:completion]
    when "active"
      stocks.where(completed_at: nil)
    when "completed"
      stocks.where.not(completed_at: nil)
    else
      stocks
    end
  end

  def stock_filter_params
    params.permit(:environment, :location_id, :plant_id, :stage, :sale_ready, :completion)
  end

  def stock_params
    params.require(:stock).permit(:location_id, :potted_on, :memo)
  end

  def create_stock_params
    params.require(:stock).permit(
      :plant_id,
      :location_id,
      :stage,
      :stage_started_on,
      :potted_on,
      :memo
    )
  end

  def create_stock_attributes
    values = create_stock_params
    {
      plant_id: values[:plant_id],
      location_id: values[:location_id],
      stage: values[:stage],
      stage_started_on: values[:stage_started_on],
      potted_on: values[:potted_on].presence,
      memo: values[:memo].presence
    }
  end

  def advance_stage_params
    params.require(:stock_stage).permit(:stage_started_on)
  end

  def sale_ready_params
    params.require(:sale_ready).permit(:sale_ready_on)
  end

  def complete_params
    params.require(:completion).permit(:completion_reason, :completed_at)
  end

  def error_messages(error)
    return error.record.errors.full_messages.join(", ") if error.respond_to?(:record)

    error.message
  end
end
