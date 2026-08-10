class RemoveStockParentIdFromStock < ActiveRecord::Migration[8.1]
  def change
    remove_reference :stocks, :parent_stock, foreign_key: { to_table: :stocks }, type: :bigint, comment: "親株のID"
    remove_column :stocks, :parent_stock_candidate, :boolean,
                  default: false, null: false, comment: "親株として選択可能か"
  end
end
