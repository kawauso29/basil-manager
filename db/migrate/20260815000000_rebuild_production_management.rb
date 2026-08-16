class RebuildProductionManagement < ActiveRecord::Migration[8.1]
  LEGACY_BUSINESS_DATA_TABLES = %i[
    plants
    locations
    stocks
    stock_observations
    stock_action_logs
    active_storage_attachments
    active_storage_variant_records
    active_storage_blobs
  ].freeze

  def up
    abort_if_records_exist!(LEGACY_BUSINESS_DATA_TABLES)

    create_table :production_lots, comment: "生産開始単位を管理するテーブル" do |t|
      t.references :plant, null: false, foreign_key: true, comment: "植物ID"
      t.references :source_stock,
                   foreign_key: { to_table: :stocks },
                   comment: "挿し穂を採取した親株ID"
      t.string :propagation_method, null: false, comment: "生産方法"
      t.date :started_on, null: false, comment: "生産開始日"
      t.integer :initial_quantity, null: false, comment: "開始数量"
      t.text :memo, comment: "メモ"
      t.timestamps
    end
    add_check_constraint :production_lots,
                         "initial_quantity > 0",
                         name: "production_lots_initial_quantity_positive"

    create_table :nursery_groups, comment: "鉢上げ前の苗群を管理するテーブル" do |t|
      t.references :production_lot, null: false, foreign_key: true, comment: "生産ロットID"
      t.references :location, null: false, foreign_key: true, comment: "管理場所ID"
      t.string :stage, null: false, comment: "現在工程"
      t.string :growing_method, null: false, comment: "育成方法"
      t.string :container_type, comment: "容器種類"
      t.integer :quantity, null: false, comment: "現在数量"
      t.date :stage_started_on, null: false, comment: "現工程の開始日"
      t.text :memo, comment: "メモ"
      t.timestamps
    end
    add_check_constraint :nursery_groups,
                         "quantity >= 0",
                         name: "nursery_groups_quantity_non_negative"

    rename_column :stocks, :status, :stage
    change_column_comment :stocks, :stage, from: "株の管理ステータス", to: "現在工程"
    add_reference :stocks,
                  :source_nursery_group,
                  foreign_key: { to_table: :nursery_groups },
                  comment: "鉢上げ元の苗グループID"
    add_column :stocks, :stage_started_on, :date, null: false, comment: "現工程の開始日"
    add_column :stocks, :potted_on, :date, comment: "個体管理へ切り替えた鉢上げ日"
    add_column :stocks, :sale_ready_on, :date, comment: "販売可能日"
    change_column_comment :stocks,
                          :completed_at,
                          from: "株の育成が完了した日時",
                          to: "株の管理が完了した日時"
    change_column_comment :stocks,
                          :completion_reason,
                          from: "株の育成完了理由",
                          to: "株の管理完了理由"
    remove_column :stocks, :code, :string, null: false, comment: "株単位の識別子"
    remove_column :stocks, :label, :string, comment: "表示名"
    remove_column :stocks, :growing_method, :string, null: false, comment: "株の栽培方法"
    remove_column :stocks, :propagation_method, :string, comment: "株の増殖方法"

    change_column_null :stock_observations, :recorded_at, false
    add_check_constraint :stock_observations,
                         "height_cm IS NULL OR height_cm >= 0",
                         name: "stock_observations_height_non_negative"

    drop_table :stock_action_logs do |t|
      t.references :stock, null: false, foreign_key: true, comment: "株ID"
      t.string :action_type, null: false, comment: "アクションログの種類"
      t.references :from_location, foreign_key: { to_table: :locations }, comment: "変更前の管理場所ID"
      t.references :to_location, foreign_key: { to_table: :locations }, comment: "変更後の管理場所ID"
      t.string :status_before, comment: "変更前の管理状態"
      t.string :status_after, comment: "変更後の管理状態"
      t.text :memo, comment: "アクションログのメモ"
      t.datetime :recorded_at, comment: "アクションログの記録日時"
      t.timestamps
    end

    remove_column :plants, :prefix, :string, null: false, comment: "管理プレフィックス"
    remove_column :plants, :last_stock_number, :integer, default: 0, comment: "最後に発行した株番号"
    remove_column :locations, :prefix, :string, null: false, comment: "管理プレフィックス"
  end

  def down
    abort_if_records_exist!(%i[
      production_lots
      nursery_groups
      stocks
      stock_observations
      plants
      locations
      active_storage_attachments
      active_storage_variant_records
      active_storage_blobs
    ])

    add_column :plants, :prefix, :string, null: false, comment: "管理プレフィックス"
    add_index :plants, :prefix, unique: true
    add_column :plants, :last_stock_number, :integer, default: 0, comment: "最後に発行した株番号"
    add_column :locations, :prefix, :string, null: false, comment: "管理プレフィックス"
    add_index :locations, :prefix, unique: true

    create_table :stock_action_logs, comment: "株への作業実行記録を行うテーブル" do |t|
      t.references :stock, null: false, foreign_key: true, comment: "株ID"
      t.string :action_type, null: false, comment: "アクションログの種類"
      t.references :from_location, foreign_key: { to_table: :locations }, comment: "変更前の管理場所ID"
      t.references :to_location, foreign_key: { to_table: :locations }, comment: "変更後の管理場所ID"
      t.string :status_before, comment: "変更前の管理状態"
      t.string :status_after, comment: "変更後の管理状態"
      t.text :memo, comment: "アクションログのメモ"
      t.datetime :recorded_at, comment: "アクションログの記録日時"
      t.timestamps
    end

    remove_check_constraint :stock_observations, name: "stock_observations_height_non_negative"
    change_column_null :stock_observations, :recorded_at, true

    add_column :stocks, :code, :string, null: false, comment: "株単位の識別子"
    add_index :stocks, :code, unique: true
    add_column :stocks, :label, :string, comment: "表示名"
    add_column :stocks, :growing_method, :string, null: false, comment: "株の栽培方法"
    add_column :stocks, :propagation_method, :string, comment: "株の増殖方法"
    change_column_comment :stocks,
                          :completed_at,
                          from: "株の管理が完了した日時",
                          to: "株の育成が完了した日時"
    change_column_comment :stocks,
                          :completion_reason,
                          from: "株の管理完了理由",
                          to: "株の育成完了理由"
    remove_column :stocks, :sale_ready_on, :date, comment: "販売可能日"
    remove_column :stocks, :potted_on, :date, comment: "個体管理へ切り替えた鉢上げ日"
    remove_column :stocks, :stage_started_on, :date, null: false, comment: "現工程の開始日"
    remove_reference :stocks,
                     :source_nursery_group,
                     foreign_key: { to_table: :nursery_groups },
                     comment: "鉢上げ元の苗グループID"
    change_column_comment :stocks, :stage, from: "現在工程", to: "株の管理ステータス"
    rename_column :stocks, :stage, :status

    remove_check_constraint :nursery_groups, name: "nursery_groups_quantity_non_negative"
    drop_table :nursery_groups
    remove_check_constraint :production_lots, name: "production_lots_initial_quantity_positive"
    drop_table :production_lots
  end

  private

  def abort_if_records_exist!(table_names)
    populated_tables = table_names.select do |table_name|
      next false unless table_exists?(table_name)

      connection.select_value(
        "SELECT 1 FROM #{connection.quote_table_name(table_name)} LIMIT 1"
      ).present?
    end
    return if populated_tables.empty?

    raise ActiveRecord::MigrationError,
          "既存業務データがあるため移行を中止しました: #{populated_tables.join(', ')}"
  end
end
