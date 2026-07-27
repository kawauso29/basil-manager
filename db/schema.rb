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

ActiveRecord::Schema[8.1].define(version: 2026_07_27_040000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stock_action_logs", comment: "株への作業実行記録を行うテーブル", force: :cascade do |t|
    t.string "action_type", null: false, comment: "アクションログの種類"
    t.datetime "created_at", null: false
    t.bigint "from_location_id", comment: "変更前の管理場所ID"
    t.text "memo", comment: "アクションログのメモ"
    t.integer "quantity_after", comment: "変更後の数量"
    t.integer "quantity_before", comment: "変更前の数量"
    t.datetime "recorded_at", comment: "アクションログの記録日時"
    t.string "status_after", comment: "変更後の管理状態"
    t.string "status_before", comment: "変更前の管理状態"
    t.bigint "stock_id", null: false, comment: "株ID"
    t.bigint "to_location_id", comment: "変更後の管理場所ID"
    t.datetime "updated_at", null: false
    t.index ["from_location_id"], name: "index_stock_action_logs_on_from_location_id"
    t.index ["stock_id"], name: "index_stock_action_logs_on_stock_id"
    t.index ["to_location_id"], name: "index_stock_action_logs_on_to_location_id"
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
    t.text "memo", comment: "管理単位についてのメモ"
    t.bigint "parent_stock_id", comment: "親株のID"
    t.bigint "plant_id", null: false, comment: "植物ID"
    t.string "propagation_method", comment: "株の増殖方法"
    t.string "public_token", null: false, comment: "公開用の株単位のトークン識別子"
    t.integer "quantity", default: 1, null: false, comment: "管理単位に含まれる株数"
    t.string "status", null: false, comment: "株の管理ステータス"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_stocks_on_code", unique: true
    t.index ["location_id"], name: "index_stocks_on_location_id"
    t.index ["parent_stock_id"], name: "index_stocks_on_parent_stock_id"
    t.index ["plant_id"], name: "index_stocks_on_plant_id"
    t.index ["public_token"], name: "index_stocks_on_public_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "location_observations", "locations"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stock_action_logs", "locations", column: "from_location_id"
  add_foreign_key "stock_action_logs", "locations", column: "to_location_id"
  add_foreign_key "stock_action_logs", "stocks"
  add_foreign_key "stock_observations", "stocks"
  add_foreign_key "stocks", "locations"
  add_foreign_key "stocks", "plants"
  add_foreign_key "stocks", "stocks", column: "parent_stock_id"
end
