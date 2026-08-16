require "rails_helper"
require Rails.root.join("db/migrate/20260815000000_rebuild_production_management")

RSpec.describe RebuildProductionManagement do
  subject(:migration) { described_class.new }

  it "業務データとActive Storageデータを移行前確認の対象にする" do
    expect(described_class::LEGACY_BUSINESS_DATA_TABLES).to contain_exactly(
      :plants,
      :locations,
      :stocks,
      :stock_observations,
      :stock_action_logs,
      :active_storage_attachments,
      :active_storage_variant_records,
      :active_storage_blobs
    )
  end

  it "対象テーブルにデータがあれば削除せず移行を中止する" do
    plant = Plant.create!(name: "バジル", code: "basil")

    expect {
      migration.migrate(:up)
    }.to raise_error(ActiveRecord::MigrationError, /plants/)
    expect(Plant.find(plant.id)).to eq(plant)
  end
end
