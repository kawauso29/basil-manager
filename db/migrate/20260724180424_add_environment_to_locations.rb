class AddEnvironmentToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :environment, :string, default: "indoor", null: false, comment: "屋内・屋外の区分"
  end
end
