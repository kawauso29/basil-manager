require "rails_helper"

RSpec.describe "Admin::Plants", type: :request do
  let(:care_guide_params) do
    {
      scientific_name: "Ocimum basilicum",
      temperature_requirements: "生育適温は20〜30℃",
      climate_requirements: "暖かい気候を好む",
      growing_season: "4〜10月",
      sunlight_requirements: "直射日光を1日6時間以上",
      watering_guide: "土の表面が乾いたらたっぷり",
      fertilizing_guide: "2〜3週間に1回",
      ventilation_requirements: "株元へ風を通す",
      soil_requirements: "水はけと保水性のよい土",
      pruning_guide: "節の上で摘芯する",
      overwintering_guide: "基本は一年草",
      care_notes: "継続して収穫する",
      care_cautions: "過湿に注意"
    }
  end

  # index
  describe "GET /admin/plants" do
    it "保存済みのPlantが一覧に表示される" do
      plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
      get admin_plants_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_admin_plant_path(plant))
    end
  end

  # show
  describe "GET /admin/plants/:id" do
    it "保存済みのPlant詳細が表示される" do
      plant = Plant.create!(
        name: "テストプラント",
        code: "test",
        prefix: "TST",
        scientific_name: "Ocimum basilicum",
        watering_guide: "土の表面が乾いたらたっぷり"
      )
      get admin_plant_path(plant), headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ocimum basilicum")
      expect(response.body).to include("土の表面が乾いたらたっぷり")
    end
  end

  # new
  describe "GET /admin/plants/new" do
    it "新規Plant作成画面が表示される" do
      get new_admin_plant_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="plant[image]"')
    end
  end

  # create
  describe "POST /admin/plants" do
    context "パラメータが正常な場合" do
      it "Plantを作成できる" do
        valid_params = {
          plant: {
            name: "テストプラント",
            code: "test",
            prefix: "TST",
            image: fixture_file_upload(Rails.root.join("public/icon.png"), "image/png"),
            **care_guide_params
          }
        }

        expect {
          post admin_plants_path, params: valid_params, headers: admin_headers
        }.to change(Plant, :count).by(1)

        created_plant = Plant.last

        # 作成値を検証
        expect(created_plant.name).to eq("テストプラント")
        expect(created_plant.code).to eq("test")
        expect(created_plant.prefix).to eq("TST")
        expect(created_plant.last_stock_number).to eq(0)
        expect(created_plant.image).to be_attached
        expect(created_plant.attributes).to include(
          care_guide_params.stringify_keys
        )

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_plant_path(created_plant))

        #
        expect(flash[:notice]).to eq("作成しました")
      end
    end

    context "パラメータが不正な場合" do
      it "Plantを作成できない" do
        invalid_params = {
          plant: { name: "テストプラント", code: "", prefix: "TST" }
        }

        expect {
          post admin_plants_path, params: invalid_params, headers: admin_headers
        }.not_to change(Plant, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end
  end

  # edit
  describe "GET /admin/plants/:id/edit" do
    it "Plant編集画面が表示される" do
      plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
      get edit_admin_plant_path(plant), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # update
  describe "PATCH /admin/plants/:id" do
    context "パラメータが正常な場合" do
      it "Plantを更新できる" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        params = {
          plant: {
            name: "更新後プラント",
            code: "test",
            prefix: "TST",
            **care_guide_params
          }
        }
        patch admin_plant_path(plant, params), headers: admin_headers
        expect(plant.reload.name).to eq("更新後プラント")
        expect(plant.attributes).to include(care_guide_params.stringify_keys)
        expect(response).to redirect_to(admin_plant_path(plant))
        expect(flash[:notice]).to include("更新しました")
      end
      it "Plantに更新がない" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        params = {
          plant: { name: "テストプラント", code: "test", prefix: "TST" }
        }
        patch admin_plant_path(plant, params), headers: admin_headers
        expect(plant.reload.name).to eq("テストプラント")
        expect(response).to redirect_to(admin_plant_path(plant))
        expect(flash[:notice]).to include("変更はありませんでした")
      end
    end
    context "パラメータが不正な場合" do
      it "Plantを更新できない" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        params = {
          plant: { name: "", code: "test", prefix: "TST" }
        }
        patch admin_plant_path(plant, params), headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/plants/:id" do
    context "子のStockを持つ場合" do
      it "Plantを削除できない" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        stock = Stocks::Creator.call(plant_id: plant.id, location_id: location.id, growing_method: "pot", propagation_method: "seed")

        delete admin_plant_path(plant), headers: admin_headers
        expect(flash.now[:alert]).to include("削除に失敗しました")
      end
    end
    context "子のStockを持たない場合" do
      it "Plantを削除できる" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")

        delete admin_plant_path(plant), headers: admin_headers
        expect(response).to redirect_to(admin_plants_path)

        expect(flash[:notice]).to eq("削除しました")
      end
    end
  end
end
