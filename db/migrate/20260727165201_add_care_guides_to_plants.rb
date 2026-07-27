class AddCareGuidesToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :scientific_name, :string, comment: "学名"
    add_column :plants, :temperature_requirements, :text, comment: "温度条件"
    add_column :plants, :climate_requirements, :text, comment: "気候条件"
    add_column :plants, :growing_season, :text, comment: "生育時期"
    add_column :plants, :sunlight_requirements, :text, comment: "日当たり条件"
    add_column :plants, :watering_guide, :text, comment: "水やりの目安"
    add_column :plants, :fertilizing_guide, :text, comment: "施肥の目安"
    add_column :plants, :ventilation_requirements, :text, comment: "風通しの条件"
    add_column :plants, :soil_requirements, :text, comment: "用土の条件"
    add_column :plants, :pruning_guide, :text, comment: "剪定の目安"
    add_column :plants, :overwintering_guide, :text, comment: "冬越しの目安"
    add_column :plants, :care_notes, :text, comment: "育成メモ"
    add_column :plants, :care_cautions, :text, comment: "育成上の注意点"
  end
end
