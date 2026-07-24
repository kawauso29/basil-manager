class Admin::LocationObservationsController < Admin::BaseController
  def index
    location_id = params[:location_id]
    @location = Location.find_by(id: location_id)
    @location_options = [["全て", ""]] + Location.pluck(:name, :id)
    @location_observations = LocationObservation.all.order(:id)
    if @location.present?
      @location_observations = @location_observations.where(location_id: location_id)
    end
  end

  def new
    @location_observation = LocationObservation.new(recorded_at: Time.current)  # <- recorded_atの初期値を現在時刻に設定
    set_form_options
  end

  def create
    @location_observation = LocationObservation.new(location_observation_params)
    if @location_observation.save
      admin_create_success_message
      redirect_to admin_location_observations_path
    else
      set_form_options
      admin_create_error_message(@location_observation)
      render :new, status: :unprocessable_content
    end
  end

  def bulk_new
    set_form_options_for_bulk_new
  end

  # ※callbackが通らないため
  # 将来的にcallbackが追加になれば
  # transaction + create! に変更
  def bulk_create
    _attr = location_observation_params
    location_ids = location_ids_param.compact_blank
    if location_ids.blank?
      set_form_options_for_bulk_new
      admin_flash_now_alert("location_idがありません")
      render :bulk_new, status: :unprocessable_content
      return
    end

    bulk_create_datas = []
    location_ids.each do |location_id|
      bulk_create_datas << {location_id: location_id}.merge(_attr)
    end

    begin
      LocationObservation.insert_all(bulk_create_datas)
      admin_create_success_message
      redirect_to admin_location_observations_path
    rescue => e
      raise "想定外のエラーです #{e.message}"
    end
  end

  # 実質未使用。現状はindexへのリダイレクトでOK
  def show
    redirect_to admin_location_observations_path
  end

  def edit
    set_form_options
    @location_observation = LocationObservation.find(params[:id])
  end

  def update
    @location_observation = LocationObservation.find(params[:id])
    if @location_observation.update(location_observation_params)
      admin_update_success_message(@location_observation)
      redirect_to edit_admin_location_observation_path(@location_observation)
    else
      set_form_options
      admin_update_error_message(@location_observation)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @location_observation = LocationObservation.find(params[:id])
    if @location_observation.destroy
      admin_destroy_success_message
      redirect_to admin_location_observations_path
    else
      # 基本ここには流れてこないはず
      set_form_options
      admin_destroy_error_message(@location_observation)
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_form_options
    @location_data = Location.order(:id).pluck(:name, :id)
    @weather_data = LocationObservation.weathers_i18n.map do |value, label|
      [label, value]
    end
  end

  def set_form_options_for_bulk_new
    @locations = Location.order(:id)
    @weather_data = LocationObservation.weathers_i18n.map do |value, label|
      [label, value]
    end
    @recorded_at = Time.current
  end

  def location_observation_params
    params.require(:location_observation).permit(
      :location_id,
      :temperature,
      :weather,
      :memo,
      :recorded_at,
    )
  end

  def location_ids_param
    params.require(:location_observation)
    .permit(location_ids: [])
    .fetch(:location_ids, [])
  end
end
