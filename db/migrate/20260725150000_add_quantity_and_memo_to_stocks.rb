class AddQuantityAndMemoToStocks < ActiveRecord::Migration[8.1]
  def change
    add_column :stocks, :quantity, :integer, null: false, default: 1, comment: "管理単位に含まれる株数"
    add_column :stocks, :memo, :text, comment: "管理単位についてのメモ"
  end
end
