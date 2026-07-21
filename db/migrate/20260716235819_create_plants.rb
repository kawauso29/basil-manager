class CreatePlants < ActiveRecord::Migration[8.1]
  def change
    create_table :plants, comment: "植物の種類を管理するテーブル" do |t|
      t.string :code, null: false, index: {unique: true}, comment: "管理コード"
      t.string :prefix, null: false, index: {unique: true}, comment: "管理プレフィックス"
      t.string :name, null: false, index: {unique: true}, comment: "植物名"
      t.integer :last_stock_number, default: 0, comment: "最後に発行した株番号"
      t.timestamps
    end
  end
end
