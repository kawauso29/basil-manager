class StockObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_observations, comment: "株の観察記録を行うテーブル" do |t|
      t.references :stock, null: false, foreign_key: true, comment: "株ID"
      t.decimal :height_cm, precision: 10, scale: 2, comment: "高さ (cm)"
      t.text :memo, comment: "観察メモ"
      t.datetime :recorded_at, comment: "観察記録日時"
      t.timestamps
    end
  end
end
