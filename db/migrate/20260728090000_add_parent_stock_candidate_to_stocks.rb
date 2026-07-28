class AddParentStockCandidateToStocks < ActiveRecord::Migration[8.1]
  def up
    add_column :stocks,
               :parent_stock_candidate,
               :boolean,
               null: false,
               default: false,
               comment: "親株として選択可能か"

    execute <<~SQL.squish
      UPDATE stocks
      SET parent_stock_candidate = TRUE
      WHERE id IN (
        SELECT DISTINCT parent_stock_id
        FROM stocks
        WHERE parent_stock_id IS NOT NULL
      )
    SQL
  end

  def down
    remove_column :stocks, :parent_stock_candidate
  end
end
