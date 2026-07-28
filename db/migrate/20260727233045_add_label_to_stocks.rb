class AddLabelToStocks < ActiveRecord::Migration[8.1]
  def change
    add_column :stocks, :label, :string, comment: "表示名"
  end
end
