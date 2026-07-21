class CreateStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks, comment: "株を管理するテーブル" do |t|
      t.references :plant, null: false, foreign_key: true, comment: "植物ID"
      t.references :location, null: false, foreign_key: true, comment: "管理場所ID"
      t.string :code, null: false, index: {unique: true}, comment: "株単位の識別子"
      t.string :public_token, null: false, index: {unique: true}, comment: "公開用の株単位のトークン識別子"
      t.string :status,null: false, comment: "株の管理ステータス"
      t.string :growing_method, null: false, comment: "株の栽培方法"
      t.string :propagation_method, null: false, comment: "株の増殖方法"
      t.references :parent_stock, foreign_key: {to_table: :stocks}, comment: "親株のID"
      t.string :completion_reason, comment: "株の育成完了理由"
      t.datetime :completed_at, comment: "株の育成が完了した日時"
      t.timestamps
    end
  end
end
