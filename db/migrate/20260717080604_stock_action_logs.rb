class StockActionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_action_logs, comment: "株への作業実行記録を行うテーブル" do |t|
      t.references :stock, null: false, foreign_key: true, comment: "株ID"
      t.string :action_type, null: false, comment: "アクションログの種類"
      t.text :memo, comment: "アクションログのメモ"
      t.datetime :recorded_at, comment: "アクションログの記録日時"
      t.timestamps
    end
  end
end
