require "rails_helper"

RSpec.describe "Admin::NurseryGroups", type: :request do
  let!(:plant) { Plant.create!(name: "バジル", code: "basil") }
  let!(:location) do
    Location.create!(name: "育苗棚", code: "nursery-shelf", environment: "indoor")
  end
  let!(:destination) do
    Location.create!(name: "順化棚", code: "acclimation-shelf", environment: "outdoor")
  end
  let!(:production_lot) do
    StartProduction.call(
      plant_id: plant.id,
      propagation_method: "cutting",
      started_on: Date.new(2026, 8, 14),
      initial_quantity: 10,
      location_id: location.id,
      growing_method: "water",
      container_type: "コップ"
    )
  end
  let!(:nursery_group) { production_lot.nursery_groups.first }

  def advance_to_pot_up_ready!
    AdvanceNurseryGroup.call(
      nursery_group: nursery_group,
      quantity: nursery_group.quantity,
      recorded_on: Date.new(2026, 8, 15)
    )
    AdvanceNurseryGroup.call(
      nursery_group: nursery_group,
      quantity: nursery_group.quantity,
      recorded_on: Date.new(2026, 8, 16)
    )
  end

  describe "GET /admin/nursery_groups" do
    it "苗グループを一覧表示する" do
      get admin_nursery_groups_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "NG-#{nursery_group.id}",
        "LOT-#{production_lot.id}",
        "10株",
        location.name
      )
    end
  end

  describe "GET /admin/nursery_groups/:id" do
    it "現在値と操作導線を表示する" do
      get admin_nursery_group_path(nursery_group), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "NG-#{nursery_group.id}",
        "次工程へ進める",
        "数量を補正",
        "条件を編集"
      )
      expect(response.body).not_to include("9cm")
    end
  end

  describe "GET /admin/nursery_groups/:id/edit" do
    it "育成条件だけを編集するフォームを表示する" do
      get edit_admin_nursery_group_path(nursery_group), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'name="nursery_group[location_id]"',
        'name="nursery_group[growing_method]"',
        'name="nursery_group[container_type]"',
        'name="nursery_group[memo]"'
      )
      expect(response.body).not_to include('name="nursery_group[quantity]"')
    end
  end

  describe "GET /admin/nursery_groups/:id/advance" do
    it "数量と次工程開始日の入力フォームを表示する" do
      get advance_admin_nursery_group_path(nursery_group), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'name="advance[quantity]"',
        'name="advance[recorded_on]"',
        "発根済み"
      )
    end
  end

  describe "GET /admin/nursery_groups/:id/correct_quantity" do
    it "現在数量の補正フォームを表示する" do
      get correct_quantity_admin_nursery_group_path(nursery_group), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="correction[quantity]"', "0株にすると終了扱い")
    end
  end

  describe "GET /admin/nursery_groups/:id/pot_up" do
    it "鉢上げ準備済みGroupに個体化の入力フォームを表示する" do
      advance_to_pot_up_ready!

      get pot_up_admin_nursery_group_path(nursery_group), headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'name="pot_up[quantity]"',
        'name="pot_up[location_id]"',
        'name="pot_up[potted_on]"'
      )
      expect(response.body).not_to include("9cm")
    end
  end

  describe "PATCH /admin/nursery_groups/:id" do
    it "グループ全体の育成条件を更新する" do
      patch admin_nursery_group_path(nursery_group),
            params: {
              nursery_group: {
                location_id: destination.id,
                growing_method: "soil",
                container_type: "セルトレー",
                memo: "全体を移動"
              }
            },
            headers: admin_headers

      expect(response).to redirect_to(admin_nursery_group_path(nursery_group))
      expect(nursery_group.reload).to have_attributes(
        location_id: destination.id,
        growing_method: "soil",
        container_type: "セルトレー",
        memo: "全体を移動"
      )
    end
  end

  describe "POST /admin/nursery_groups/:id/advance" do
    it "一部数量を次工程の新しいGroupへ進める" do
      expect {
        post advance_admin_nursery_group_path(nursery_group),
             params: { advance: { quantity: 4, recorded_on: "2026-08-15" } },
             headers: admin_headers
      }.to change(NurseryGroup, :count).by(1)

      advanced_group = NurseryGroup.order(:id).last
      expect(response).to redirect_to(admin_nursery_group_path(advanced_group))
      expect(nursery_group.reload.quantity).to eq(6)
      expect(advanced_group).to have_attributes(
        production_lot_id: production_lot.id,
        stage: "rooted",
        quantity: 4,
        stage_started_on: Date.new(2026, 8, 15)
      )
    end

    it "全数量なら同じGroupを更新する" do
      expect {
        post advance_admin_nursery_group_path(nursery_group),
             params: { advance: { quantity: 10, recorded_on: "2026-08-15" } },
             headers: admin_headers
      }.not_to change(NurseryGroup, :count)

      expect(response).to redirect_to(admin_nursery_group_path(nursery_group))
      expect(nursery_group.reload).to have_attributes(
        stage: "rooted",
        quantity: 10,
        stage_started_on: Date.new(2026, 8, 15)
      )
    end

    it "現在数量を超える入力を拒否する" do
      post advance_admin_nursery_group_path(nursery_group),
           params: { advance: { quantity: 11, recorded_on: "2026-08-15" } },
           headers: admin_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(nursery_group.reload.quantity).to eq(10)
    end

    it "整数でない数量を拒否する" do
      expect {
        post advance_admin_nursery_group_path(nursery_group),
             params: { advance: { quantity: "1.5", recorded_on: "2026-08-15" } },
             headers: admin_headers
      }.not_to change(NurseryGroup, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(nursery_group.reload.quantity).to eq(10)
    end
  end

  describe "PATCH /admin/nursery_groups/:id/correct_quantity" do
    it "現在数量を履歴なしで補正する" do
      patch correct_quantity_admin_nursery_group_path(nursery_group),
            params: { correction: { quantity: 7 } },
            headers: admin_headers

      expect(response).to redirect_to(admin_nursery_group_path(nursery_group))
      expect(nursery_group.reload.quantity).to eq(7)
    end

    it "0株へ補正して終了扱いにできる" do
      patch correct_quantity_admin_nursery_group_path(nursery_group),
            params: { correction: { quantity: 0 } },
            headers: admin_headers

      get admin_nursery_group_path(nursery_group), headers: admin_headers
      expect(response.body).to include("終了")
      expect(response.body).not_to include("次工程へ進める")
    end

    it "不正な数量を0株として扱わない" do
      patch correct_quantity_admin_nursery_group_path(nursery_group),
            params: { correction: { quantity: "abc" } },
            headers: admin_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(nursery_group.reload.quantity).to eq(10)
    end

    it "先頭が0でも十進数として扱う" do
      patch correct_quantity_admin_nursery_group_path(nursery_group),
            params: { correction: { quantity: "08" } },
            headers: admin_headers

      expect(response).to redirect_to(admin_nursery_group_path(nursery_group))
      expect(nursery_group.reload.quantity).to eq(8)
    end
  end

  describe "POST /admin/nursery_groups/:id/pot_up" do
    it "指定数のStockを作り、Group数量を減らす" do
      advance_to_pot_up_ready!

      expect {
        post pot_up_admin_nursery_group_path(nursery_group),
             params: {
               pot_up: {
                 quantity: 3,
                 location_id: destination.id,
                 potted_on: "2026-08-17"
               }
             },
             headers: admin_headers
      }.to change(Stock, :count).by(3)

      expect(response).to redirect_to(admin_nursery_group_path(nursery_group))
      expect(flash[:notice]).to eq("3株を鉢上げしました")
      expect(nursery_group.reload.quantity).to eq(7)
      expect(Stock.order(:id).last(3)).to all(have_attributes(
        plant_id: plant.id,
        location_id: destination.id,
        source_nursery_group_id: nursery_group.id,
        stage: "acclimating",
        potted_on: Date.new(2026, 8, 17)
      ))
    end

    it "鉢上げ準備前は処理しない" do
      expect {
        post pot_up_admin_nursery_group_path(nursery_group),
             params: {
               pot_up: {
                 quantity: 1,
                 location_id: destination.id,
                 potted_on: "2026-08-17"
               }
             },
             headers: admin_headers
      }.not_to change(Stock, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(nursery_group.reload.quantity).to eq(10)
    end

    it "整数でない数量を拒否する" do
      advance_to_pot_up_ready!

      expect {
        post pot_up_admin_nursery_group_path(nursery_group),
             params: {
               pot_up: {
                 quantity: "1.5",
                 location_id: destination.id,
                 potted_on: "2026-08-17"
               }
             },
             headers: admin_headers
      }.not_to change(Stock, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(nursery_group.reload.quantity).to eq(10)
    end
  end
end
