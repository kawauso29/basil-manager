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

ActiveRecord::Schema[8.1].define(version: 2026_08_18_000000) do
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

  create_table "locations", comment: "植物の育成場所を管理するテーブル", force: :cascade do |t|
    t.string "code", null: false, comment: "管理コード"
    t.datetime "created_at", null: false
    t.string "environment", default: "indoor", null: false, comment: "屋内・屋外の区分"
    t.string "name", null: false, comment: "管理場所名称"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["name"], name: "index_locations_on_name", unique: true
  end

  create_table "nursery_groups", comment: "鉢上げ前の苗群を管理するテーブル", force: :cascade do |t|
    t.string "container_type", comment: "容器種類"
    t.datetime "created_at", null: false
    t.string "growing_method", null: false, comment: "育成方法"
    t.bigint "location_id", null: false, comment: "管理場所ID"
    t.text "memo", comment: "メモ"
    t.bigint "production_lot_id", null: false, comment: "生産ロットID"
    t.integer "quantity", null: false, comment: "現在数量"
    t.string "stage", null: false, comment: "現在工程"
    t.date "stage_started_on", null: false, comment: "現工程の開始日"
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_nursery_groups_on_location_id"
    t.index ["production_lot_id"], name: "index_nursery_groups_on_production_lot_id"
    t.check_constraint "quantity >= 0", name: "nursery_groups_quantity_non_negative"
  end

  create_table "plants", comment: "植物の種類を管理するテーブル", force: :cascade do |t|
    t.string "code", null: false, comment: "管理コード"
    t.datetime "created_at", null: false
    t.string "name", null: false, comment: "植物名"
    t.string "scientific_name", comment: "学名"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plants_on_code", unique: true
    t.index ["name"], name: "index_plants_on_name", unique: true
  end

  create_table "production_lots", comment: "生産開始単位を管理するテーブル", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "initial_quantity", null: false, comment: "開始数量"
    t.text "memo", comment: "メモ"
    t.bigint "plant_id", null: false, comment: "植物ID"
    t.string "propagation_method", null: false, comment: "生産方法"
    t.bigint "source_stock_id", comment: "挿し穂を採取した親株ID"
    t.date "started_on", null: false, comment: "生産開始日"
    t.datetime "updated_at", null: false
    t.index ["plant_id"], name: "index_production_lots_on_plant_id"
    t.index ["source_stock_id"], name: "index_production_lots_on_source_stock_id"
    t.check_constraint "initial_quantity > 0", name: "production_lots_initial_quantity_positive"
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

  create_table "stock_observations", comment: "株の観察記録を行うテーブル", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "height_cm", precision: 10, scale: 2, comment: "高さ (cm)"
    t.text "memo", comment: "観察メモ"
    t.datetime "recorded_at", null: false, comment: "観察記録日時"
    t.bigint "stock_id", null: false, comment: "株ID"
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_stock_observations_on_stock_id"
    t.check_constraint "height_cm IS NULL OR height_cm >= 0::numeric", name: "stock_observations_height_non_negative"
  end

  create_table "stocks", comment: "株を管理するテーブル", force: :cascade do |t|
    t.datetime "completed_at", comment: "株の管理が完了した日時"
    t.string "completion_reason", comment: "株の管理完了理由"
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false, comment: "管理場所ID"
    t.text "memo", comment: "株についてのメモ"
    t.bigint "plant_id", null: false, comment: "植物ID"
    t.date "potted_on", comment: "個体管理へ切り替えた鉢上げ日"
    t.string "product_type", comment: "商品形態"
    t.string "public_token", null: false, comment: "公開用の株単位のトークン識別子"
    t.date "sale_ready_on", comment: "販売可能日"
    t.bigint "source_nursery_group_id", comment: "鉢上げ元の苗グループID"
    t.string "stage", null: false, comment: "現在工程"
    t.date "stage_started_on", null: false, comment: "現工程の開始日"
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_stocks_on_location_id"
    t.index ["plant_id"], name: "index_stocks_on_plant_id"
    t.index ["public_token"], name: "index_stocks_on_public_token", unique: true
    t.index ["source_nursery_group_id"], name: "index_stocks_on_source_nursery_group_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "nursery_groups", "locations"
  add_foreign_key "nursery_groups", "production_lots"
  add_foreign_key "production_lots", "plants"
  add_foreign_key "production_lots", "stocks", column: "source_stock_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stock_observations", "stocks"
  add_foreign_key "stocks", "locations"
  add_foreign_key "stocks", "nursery_groups", column: "source_nursery_group_id"
  add_foreign_key "stocks", "plants"
end
