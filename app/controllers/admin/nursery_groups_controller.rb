class Admin::NurseryGroupsController < Admin::BaseController
  before_action :set_nursery_group, except: :index

  def index
    @nursery_groups = NurseryGroup.includes(:production_lot, :location).order(id: :desc)
  end

  def show
    set_record_navigation(@nursery_group)
    @stocks = @nursery_group.stocks.includes(:plant, :location, source_nursery_group: :production_lot).order(id: :asc)
  end

  def edit
    set_record_navigation(@nursery_group)
    set_condition_options
  end

  def update
    if @nursery_group.update(nursery_group_params)
      admin_update_success_message(@nursery_group)
      redirect_to admin_nursery_group_path(@nursery_group)
    else
      set_record_navigation(@nursery_group)
      set_condition_options
      admin_update_error_message(@nursery_group)
      render :edit, status: :unprocessable_content
    end
  end

  def advance_form
    @form_values = {
      quantity: @nursery_group.quantity,
      recorded_on: Date.current
    }
    set_advance_data
  end

  def advance
    advanced_group = AdvanceNurseryGroup.call(
      nursery_group: @nursery_group,
      quantity: parse_quantity(advance_params[:quantity]),
      recorded_on: advance_params[:recorded_on]
    )
    admin_flash_notice("NG-#{advanced_group.id}を次工程へ進めました")
    redirect_to admin_nursery_group_path(advanced_group)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @form_values = advance_params.to_h.symbolize_keys
    set_advance_data
    admin_flash_now_alert("次工程への更新に失敗しました #{error_messages(e)}")
    render :advance_form, status: :unprocessable_content
  end

  def correct_quantity_form
    @form_values = { quantity: @nursery_group.quantity }
  end

  def correct_quantity
    CorrectNurseryGroupQuantity.call(
      nursery_group: @nursery_group,
      quantity: parse_quantity(correct_quantity_params[:quantity])
    )
    admin_flash_notice("現在数量を補正しました")
    redirect_to admin_nursery_group_path(@nursery_group)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @form_values = correct_quantity_params.to_h.symbolize_keys
    admin_flash_now_alert("数量補正に失敗しました #{error_messages(e)}")
    render :correct_quantity_form, status: :unprocessable_content
  end

  def pot_up_form
    @form_values = {
      quantity: @nursery_group.quantity,
      location_id: @nursery_group.location_id,
      potted_on: Date.current
    }
    set_location_options
  end

  def pot_up
    stocks = PotUpNurseryGroup.call(
      nursery_group: @nursery_group,
      quantity: parse_quantity(pot_up_params[:quantity]),
      location_id: pot_up_params[:location_id],
      potted_on: pot_up_params[:potted_on]
    )
    admin_flash_notice("#{stocks.size}株を鉢上げしました")
    redirect_to admin_nursery_group_path(@nursery_group)
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @form_values = pot_up_params.to_h.symbolize_keys
    set_location_options
    admin_flash_now_alert("鉢上げに失敗しました #{error_messages(e)}")
    render :pot_up_form, status: :unprocessable_content
  end

  private

  def set_nursery_group
    @nursery_group = NurseryGroup.includes(:production_lot, :location).find(params[:id])
  end

  def set_condition_options
    set_location_options
    @growing_method_options = NurseryGroup.growing_methods_i18n.map do |value, label|
      [ label, value ]
    end
  end

  def set_location_options
    @location_options = Location.order(:name).pluck(:name, :id)
  end

  def set_advance_data
    @next_stage = @nursery_group.next_stage
  end

  def nursery_group_params
    params.require(:nursery_group).permit(:location_id, :growing_method, :container_type, :memo)
  end

  def advance_params
    params.require(:advance).permit(:quantity, :recorded_on)
  end

  def correct_quantity_params
    params.require(:correction).permit(:quantity)
  end

  def pot_up_params
    params.require(:pot_up).permit(:quantity, :location_id, :potted_on)
  end

  def parse_quantity(value)
    Integer(value.to_s, 10)
  end

  def error_messages(error)
    return error.record.errors.full_messages.join(", ") if error.respond_to?(:record)

    error.message
  end
end
