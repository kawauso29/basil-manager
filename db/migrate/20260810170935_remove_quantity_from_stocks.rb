class RemoveQuantityFromStocks < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM stock_action_logs WHERE action_type = 'quantity_changed'"

    remove_column :stock_action_logs, :quantity_before, :integer, comment: "変更前の数量"
    remove_column :stock_action_logs, :quantity_after, :integer, comment: "変更後の数量"
    remove_column :stocks, :quantity, :integer,
                  default: 1, null: false, comment: "管理単位に含まれる株数"
    change_column_comment :stocks, :memo, from: "管理単位についてのメモ", to: "株についてのメモ"
  end

  def down
    change_column_comment :stocks, :memo, from: "株についてのメモ", to: "管理単位についてのメモ"
    add_column :stocks, :quantity, :integer,
               default: 1, null: false, comment: "管理単位に含まれる株数"
    add_column :stock_action_logs, :quantity_before, :integer, comment: "変更前の数量"
    add_column :stock_action_logs, :quantity_after, :integer, comment: "変更後の数量"
  end
end
