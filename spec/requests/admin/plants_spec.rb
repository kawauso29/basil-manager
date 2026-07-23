require "rails_helper"

RSpec.describe "Admin::Plants", type: :request do

  # index
  describe "GET /admin/plants" do
    it "保存済みのPlantが一覧に表示される" do
      plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
      get admin_plants_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # show
  describe "GET /admin/plants/:id" do
    it "保存済みのPlant詳細が表示される" do
      plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
      get admin_plant_path(plant), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # new
  describe "GET /admin/plants/new" do
    it "新規Plant作成画面が表示される" do
      get new_admin_plant_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # create
  describe "POST /admin/plants" do
    context "パラメータが正常な場合" do
      it "Plantを作成できる" do
        valid_params = {
          plant: { name: "テストプラント", code: "test", prefix: "TST" }
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
          plant: {name: "更新後プラント", code: "test", prefix: "TST"}
        }
        patch admin_plant_path(plant, params), headers: admin_headers
        expect(plant.reload.name).to eq("更新後プラント")
        expect(response).to redirect_to(admin_plant_path(plant))
        expect(flash[:notice]).to include("更新しました")
      end
      it "Plantに更新がない" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        params = {
          plant: {name: "テストプラント", code: "test", prefix: "TST"}
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
          plant: {name: "", code: "test", prefix: "TST"}
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
        stock = Stocks::Creator.call(plant: plant, location: location, growing_method: "pot", propagation_method: "seed")

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
