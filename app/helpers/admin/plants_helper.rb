module Admin::PlantsHelper
  CARE_GUIDE_LABELS = {
    scientific_name: "学名",
    temperature_requirements: "温度",
    climate_requirements: "気候",
    growing_season: "シーズン",
    sunlight_requirements: "日当たり",
    watering_guide: "水やり",
    fertilizing_guide: "肥料",
    ventilation_requirements: "風通し",
    soil_requirements: "用土",
    pruning_guide: "剪定・切り戻し",
    overwintering_guide: "冬越し",
    care_notes: "メモ",
    care_cautions: "注意点"
  }.freeze

  def plant_care_guide_items(plant)
    CARE_GUIDE_LABELS.filter_map do |attribute, label|
      value = plant.public_send(attribute)
      [ label, value ] if value.present?
    end
  end
end
