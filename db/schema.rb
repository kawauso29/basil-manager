# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_24_180424) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "location_observations", comment: "管理場所の観察記録を行うテーブル", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false, comment: "管理場所ID"
    t.text "memo", comment: "観察メモ"
    t.datetime "recorded_at", comment: "観察記録日時"
    t.decimal "temperature", precision: 4, scale: 2, comment: "温度 (℃)"
    t.datetime "updated_at", null: false
    t.string "weather", comment: "天候"
    t.index ["location_id"], name: "index_location_observations_on_location_id"
  end

  create_table "locations", comment: "植物の育成場所を管理するテーブル", force: :cascade do |t|
    t.string "code", null: false, comment: "管理コード"
    t.datetime "created_at", null: false
    t.string "environment", default: "indoor", null: false, comment: "屋内・屋外の区分"
    t.string "name", null: false, comment: "管理場所名称"
    t.string "prefix", null: false, comment: "管理プレフィックス"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
    t.index ["prefix"], name: "index_locations_on_prefix", unique: true
  end

  create_table "plants", comment: "植物の種類を管理するテーブル", force: :cascade do |t|
    t.string "code", null: false, comment: "管理コード"
    t.datetime "created_at", null: false
    t.integer "last_stock_number", default: 0, comment: "最後に発行した株番号"
    t.string "name", null: false, comment: "植物名"
    t.string "prefix", null: false, comment: "管理プレフィックス"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plants_on_code", unique: true
    t.index ["name"], name: "index_plants_on_name", unique: true
    t.index ["prefix"], name: "index_plants_on_prefix", unique: true
  end

  create_table "stock_action_logs", comment: "株への作業実行記録を行うテーブル", force: :cascade do |t|
    t.string "action_type", null: false, comment: "アクションログの種類"
    t.datetime "created_at", null: false
    t.text "memo", comment: "アクションログのメモ"
    t.datetime "recorded_at", comment: "アクションログの記録日時"
    t.bigint "stock_id", null: false, comment: "株ID"
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_stock_action_logs_on_stock_id"
  end

  create_table "stock_observations", comment: "株の観察記録を行うテーブル", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "height_cm", precision: 10, scale: 2, comment: "高さ (cm)"
    t.text "memo", comment: "観察メモ"
    t.datetime "recorded_at", comment: "観察記録日時"
    t.bigint "stock_id", null: false, comment: "株ID"
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_stock_observations_on_stock_id"
  end

  create_table "stocks", comment: "株を管理するテーブル", force: :cascade do |t|
    t.string "code", null: false, comment: "株単位の識別子"
    t.datetime "completed_at", comment: "株の育成が完了した日時"
    t.string "completion_reason", comment: "株の育成完了理由"
    t.datetime "created_at", null: false
    t.string "growing_method", null: false, comment: "株の栽培方法"
    t.bigint "location_id", null: false, comment: "管理場所ID"
    t.bigint "parent_stock_id", comment: "親株のID"
    t.bigint "plant_id", null: false, comment: "植物ID"
    t.string "propagation_method", null: false, comment: "株の増殖方法"
    t.string "public_token", null: false, comment: "公開用の株単位のトークン識別子"
    t.string "status", null: false, comment: "株の管理ステータス"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_stocks_on_code", unique: true
    t.index ["location_id"], name: "index_stocks_on_location_id"
    t.index ["parent_stock_id"], name: "index_stocks_on_parent_stock_id"
    t.index ["plant_id"], name: "index_stocks_on_plant_id"
    t.index ["public_token"], name: "index_stocks_on_public_token", unique: true
  end

  add_foreign_key "location_observations", "locations"
  add_foreign_key "stock_action_logs", "stocks"
  add_foreign_key "stock_observations", "stocks"
  add_foreign_key "stocks", "locations"
  add_foreign_key "stocks", "plants"
  add_foreign_key "stocks", "stocks", column: "parent_stock_id"
end
