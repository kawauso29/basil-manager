require "rails_helper"

RSpec.describe "20260815_reset_all_business_data.rb" do
  let(:script_path) { Rails.root.join("db/data/20260815_reset_all_business_data.rb").to_s }
  let(:rails_env) { ActiveSupport::EnvironmentInquirer.new("test") }
  let(:connection) do
    instance_double(
      ActiveRecord::ConnectionAdapters::AbstractAdapter,
      data_source_exists?: true,
      column_exists?: true,
      quote_table_name: nil,
      quote_column_name: nil
    )
  end
  let(:blob) { instance_double(ActiveStorage::Blob) }
  let(:blob_relation) { double("blob relation", load: [ blob ]) }

  around do |example|
    original_confirm = ENV.fetch("CONFIRM", nil)
    original_production_confirm = ENV.fetch("ALLOW_PRODUCTION_RESET", nil)

    example.run
  ensure
    ENV["CONFIRM"] = original_confirm
    ENV["ALLOW_PRODUCTION_RESET"] = original_production_confirm
  end

  before do
    ENV.delete("CONFIRM")
    ENV.delete("ALLOW_PRODUCTION_RESET")
    allow(Rails).to receive(:env).and_return(rails_env)
    allow(ApplicationRecord).to receive(:connection).and_return(connection)
    allow(connection).to receive(:quote_table_name) { |name| %Q("#{name}") }
    allow(connection).to receive(:quote_column_name) { |name| %Q("#{name}") }
    allow(connection).to receive(:data_source_exists?).and_return(true)
    allow(connection).to receive(:column_exists?).and_return(true)
    allow(connection).to receive(:select_value).and_return(3)
    allow(connection).to receive(:transaction).and_yield
    allow(connection).to receive(:update)
    allow(connection).to receive(:delete)
    allow(ActiveStorage::Blob).to receive(:all).and_return(blob_relation)
    allow(blob).to receive(:delete)
    allow(blob).to receive(:destroy!)
  end

  it "対象件数とZIPの用途を表示し、確認文字列がなければ削除しない" do
    allow(connection).to receive(:data_source_exists?) do |table_name|
      table_name != "stock_action_logs"
    end

    expect {
      expect { load script_path, true }.to raise_error(SystemExit)
    }.to output(
      a_string_including("削除対象件数 (test)", "plants", "3", "stock_action_logs", "0")
    ).to_stdout.and output(
      a_string_including("AIへの本番データ提供用", "復元用バックアップではありません", "CONFIRM=")
    ).to_stderr

    expect(connection).not_to have_received(:delete)
    expect(blob).not_to have_received(:delete)
  end

  it "確認文字列が一致すればFK参照、DB行、画像実体、Blobの順に削除する" do
    ENV["CONFIRM"] = "DELETE_ALL_BASIL_MANAGER_DATA"
    events = []
    allow(connection).to receive(:update) { events << :source_stock_nullified }
    allow(connection).to receive(:delete) do |sql|
      table_name = sql.match(/DELETE FROM "([^"]+)"/).captures.first
      events << [ :database_deleted, table_name ]
    end
    allow(blob).to receive(:delete) { events << :stored_object_deleted }
    allow(blob).to receive(:destroy!) { events << :blob_deleted }

    expect { load script_path, true }.to output(
      a_string_including("全業務データとActive Storageの画像実体を削除しました")
    ).to_stdout

    expect(events).to eq([
      :source_stock_nullified,
      [ :database_deleted, "active_storage_attachments" ],
      [ :database_deleted, "active_storage_variant_records" ],
      [ :database_deleted, "stock_observations" ],
      [ :database_deleted, "stock_action_logs" ],
      [ :database_deleted, "stocks" ],
      [ :database_deleted, "nursery_groups" ],
      [ :database_deleted, "production_lots" ],
      [ :database_deleted, "locations" ],
      [ :database_deleted, "plants" ],
      :stored_object_deleted,
      :blob_deleted
    ])
  end

  it "production環境では二つ目の確認文字列がなければ削除しない" do
    ENV["CONFIRM"] = "DELETE_ALL_BASIL_MANAGER_DATA"
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    expect {
      expect { load script_path, true }.to raise_error(SystemExit)
    }.to output(
      a_string_including("ALLOW_PRODUCTION_RESET=")
    ).to_stderr

    expect(connection).not_to have_received(:delete)
  end

  it "production環境でも二つの確認文字列が一致すれば削除する" do
    ENV["CONFIRM"] = "DELETE_ALL_BASIL_MANAGER_DATA"
    ENV["ALLOW_PRODUCTION_RESET"] = "DELETE_ALL_BASIL_MANAGER_PRODUCTION_DATA"
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    expect { load script_path, true }.to output(
      a_string_including("全業務データとActive Storageの画像実体を削除しました")
    ).to_stdout

    expect(connection).to have_received(:delete).exactly(9).times
  end

  it "新旧schemaのうち存在するテーブルだけを削除する" do
    ENV["CONFIRM"] = "DELETE_ALL_BASIL_MANAGER_DATA"
    deleted_sql = []
    allow(connection).to receive(:data_source_exists?) do |table_name|
      !table_name.in?(%w[ production_lots nursery_groups stock_action_logs ])
    end
    allow(connection).to receive(:delete) { |sql| deleted_sql << sql }

    expect { load script_path, true }.not_to raise_error

    expect(connection).not_to have_received(:update)
    expect(deleted_sql.join).to include("stocks", "locations", "plants")
    expect(deleted_sql.join).not_to include("production_lots", "nursery_groups", "stock_action_logs")
  end

  it "Active Storage未導入のschemaでも実行できる" do
    ENV["CONFIRM"] = "DELETE_ALL_BASIL_MANAGER_DATA"
    allow(connection).to receive(:data_source_exists?) do |table_name|
      !table_name.start_with?("active_storage_")
    end

    expect { load script_path, true }.not_to raise_error

    expect(ActiveStorage::Blob).not_to have_received(:all)
  end

  it "画像実体の削除に失敗したBlob行を残し、再実行できる" do
    ENV["CONFIRM"] = "DELETE_ALL_BASIL_MANAGER_DATA"
    attempts = 0
    allow(blob).to receive(:delete) do
      attempts += 1
      raise StandardError, "storage unavailable" if attempts == 1
    end

    expect { load script_path, true }.to raise_error(StandardError, "storage unavailable")
    expect(blob).not_to have_received(:destroy!)

    expect { load script_path, true }.not_to raise_error
    expect(blob).to have_received(:destroy!).once
  end
end
