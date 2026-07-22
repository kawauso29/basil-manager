class Admin::PlantsController < Admin::BaseController
  def index
    @plants = Plant.all
  end

  def new
    @plant = Plant.new
  end

  def create
    @plant = Plant.new(plant_params)
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
  end

  def edit
    @plant = Plant.find(params[:id])
  end

  def update
    @plant = Plant.find(params[:id])
    if @plant.update(plant_params)
      admin_update_success_message(@plant)
      redirect_to admin_plant_path(@plant)
    else
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
      admin_destroy_error_message(@plant)
      render :show, status: :unprocessable_content
    end
  end

  private

  def plant_params
    params.require(:plant).permit(:name, :code, :prefix, :last_stock_number)
  end
end
