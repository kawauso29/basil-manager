class AddChangeDetailsToStockActionLogs < ActiveRecord::Migration[8.1]
  def change
    change_table :stock_action_logs, bulk: true do |t|
      t.integer :quantity_before, comment: "変更前の数量"
      t.integer :quantity_after, comment: "変更後の数量"
      t.string :status_before, comment: "変更前の管理状態"
      t.string :status_after, comment: "変更後の管理状態"
      t.references :from_location, foreign_key: { to_table: :locations }, comment: "変更前の管理場所ID"
      t.references :to_location, foreign_key: { to_table: :locations }, comment: "変更後の管理場所ID"
    end
  end
end
