class AddPublicPageToStocks < ActiveRecord::Migration[8.1]
  def change
    add_column :stocks, :published_at, :datetime, comment: "公開ページを公開した日時"
    add_index :stocks, :published_at
    add_column :stocks, :product_type, :string, comment: "商品形態"
  end
end
