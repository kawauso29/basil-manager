class Admin::LocationsController < Admin::BaseController
  include Admin::ImageAttachment

  def index
    @locations = Location.all.order(id: :asc)
  end

  def new
    set_form_options
    @location = Location.new
  end

  def create
    @location = Location.new(location_params.except(:image))
    attach_resized_image(@location, location_params[:image])
    if @location.save
      admin_create_success_message
      redirect_to admin_location_path(@location)
    else
      set_form_options
      admin_create_error_message(@location)
      render :new, status: :unprocessable_content
    end
  end

  def show
    @location = Location.find(params[:id])
    set_record_navigation(@location)
    set_show_data
  end

  def edit
    set_form_options
    @location = Location.find(params[:id])
    set_record_navigation(@location)
  end

  def update
    @location = Location.find(params[:id])
    @location.assign_attributes(location_params.except(:image))
    attach_resized_image(@location, location_params[:image])
    if @location.save
      admin_update_success_message(@location)
      redirect_to admin_location_path(@location)
    else
      set_form_options
      set_record_navigation(@location)
      admin_update_error_message(@location)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @location = Location.find(params[:id])
    if @location.destroy
      admin_destroy_success_message
      redirect_to admin_locations_path
    else
      set_record_navigation(@location)
      set_show_data
      admin_destroy_error_message(@location)
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_show_data
    @stocks = @location.stocks.order(:id).to_a
  end

  def location_params
    params.require(:location).permit(
      :name,
      :code,
      :prefix,
      :environment,
      :image
    )
  end

  def set_form_options
    @environment_data = Location.environments_i18n.map do |value, label|
      [ label, value ]
    end
  end
end
