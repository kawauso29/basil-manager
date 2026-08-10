class Admin::PlantsController < Admin::BaseController
  include Admin::ImageAttachment

  def index
    @plants = Plant.all.order(id: :asc)
  end

  def new
    @plant = Plant.new
  end

  def create
    @plant = Plant.new(plant_params.except(:image))
    attach_resized_image(@plant, plant_params[:image])
    if @plant.save
      admin_create_success_message
      redirect_to admin_plant_path(@plant)
    else
      admin_create_error_message(@plant)
      render :new, status: :unprocessable_content
    end
  end

  def show
    @plant = Plant.find(params[:id])
    set_record_navigation(@plant)
    set_show_data
  end

  def edit
    @plant = Plant.find(params[:id])
    set_record_navigation(@plant)
  end

  def update
    @plant = Plant.find(params[:id])
    @plant.assign_attributes(plant_params.except(:image))
    attach_resized_image(@plant, plant_params[:image])
    if @plant.save
      admin_update_success_message(@plant)
      redirect_to admin_plant_path(@plant)
    else
      set_record_navigation(@plant)
      admin_update_error_message(@plant)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @plant = Plant.find(params[:id])
    if @plant.destroy
      admin_destroy_success_message
      redirect_to admin_plants_path
    else
      set_record_navigation(@plant)
      set_show_data
      admin_destroy_error_message(@plant)
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_show_data
    @stocks = @plant.stocks.order(:id).to_a
  end

  def plant_params
    params.require(:plant).permit(
      :name,
      :code,
      :prefix,
      :last_stock_number,
      :scientific_name,
      :image
    )
  end
end
