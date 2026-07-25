class MakePropagationMethodNullableOnStocks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :stocks, :propagation_method, true
  end
end
