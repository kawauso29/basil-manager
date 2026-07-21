class LocationObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :location_observations, comment: "管理場所の観察記録を行うテーブル" do |t|
      t.references :location, null: false, foreign_key: true, comment: "管理場所ID"
      t.decimal :temperature, precision: 4, scale: 2, comment: "温度 (℃)"
      t.string :weather, comment: "天候"
      t.text :memo, comment: "観察メモ"
      t.datetime :recorded_at, comment: "観察記録日時"
      t.timestamps
    end
  end
end
