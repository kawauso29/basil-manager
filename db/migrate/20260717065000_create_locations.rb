class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations, comment: "植物の育成場所を管理するテーブル" do |t|
      t.string :code, null: false, index: {unique: true}, comment: "管理コード"
      t.string :prefix, null: false, index: {unique: true}, comment: "管理プレフィックス"
      t.string :name, null: false, index: {unique: true}, comment: "管理場所名称"
      t.timestamps
    end
  end
end
