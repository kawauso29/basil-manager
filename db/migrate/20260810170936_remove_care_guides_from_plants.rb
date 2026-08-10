class RemoveCareGuidesFromPlants < ActiveRecord::Migration[8.1]
  def change
    remove_column :plants, :temperature_requirements, :text, comment: "温度条件"
    remove_column :plants, :climate_requirements, :text, comment: "気候条件"
    remove_column :plants, :growing_season, :text, comment: "生育時期"
    remove_column :plants, :sunlight_requirements, :text, comment: "日当たり条件"
    remove_column :plants, :watering_guide, :text, comment: "水やりの目安"
    remove_column :plants, :fertilizing_guide, :text, comment: "施肥の目安"
    remove_column :plants, :ventilation_requirements, :text, comment: "風通しの条件"
    remove_column :plants, :soil_requirements, :text, comment: "用土の条件"
    remove_column :plants, :pruning_guide, :text, comment: "剪定の目安"
    remove_column :plants, :overwintering_guide, :text, comment: "冬越しの目安"
    remove_column :plants, :care_notes, :text, comment: "育成メモ"
    remove_column :plants, :care_cautions, :text, comment: "育成上の注意点"
  end
end
