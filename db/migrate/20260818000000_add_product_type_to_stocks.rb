class AddProductTypeToStocks < ActiveRecord::Migration[8.1]
  def change
    add_column :stocks, :product_type, :string, comment: "商品形態"
  end
end
