require "rails_helper"

RSpec.describe "Admin::Locations", type: :request do

  # index
  describe "GET /admin/locations" do
    it "保存済みのLocationが一覧に表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      get admin_locations_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # show
  describe "GET /admin/locations/:id" do
    it "保存済みのLocation詳細が表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      get admin_location_path(location), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # new
  describe "GET /admin/locations/new" do
    it "新規Location作成画面が表示される" do
      get new_admin_location_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # create
  describe "POST /admin/locations" do
    context "パラメータが正常な場合" do
      it "Locationを作成できる" do
        valid_params = {
          location: { name: "テストロケーション", code: "test", prefix: "TST" }
        }

        expect {
          post admin_locations_path, params: valid_params, headers: admin_headers
        }.to change(Location, :count).by(1)

        created_location = Location.last

        # 作成値を検証
        expect(created_location.name).to eq("テストロケーション")
        expect(created_location.code).to eq("test")
        expect(created_location.prefix).to eq("TST")

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_location_path(created_location))

        #
        expect(flash[:notice]).to eq("作成しました")
      end
    end

    context "パラメータが不正な場合" do
      it "Locationを作成できない" do
        invalid_params = {
          location: { name: "テストロケーション", code: "", prefix: "TST" }
        }

        expect {
          post admin_locations_path, params: invalid_params, headers: admin_headers
        }.not_to change(Location, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end
  end

  # edit
  describe "GET /admin/locations/:id/edit" do
    it "Location編集画面が表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      get edit_admin_location_path(location), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # update
  describe "PATCH /admin/locations/:id" do
    context "パラメータが正常な場合" do
      it "Locationを更新できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        params = {
          location: {name: "更新後ロケーション", code: "test", prefix: "TST"}
        }
        patch admin_location_path(location, params), headers: admin_headers
        expect(location.reload.name).to eq("更新後ロケーション")
        expect(response).to redirect_to(admin_location_path(location))
        expect(flash[:notice]).to include("更新しました")
      end
      it "Locationに更新がない" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        params = {
          location: {name: "テストロケーション", code: "test", prefix: "TST"}
        }
        patch admin_location_path(location, params), headers: admin_headers
        expect(location.reload.name).to eq("テストロケーション")
        expect(response).to redirect_to(admin_location_path(location))
        expect(flash[:notice]).to include("変更はありませんでした")
      end
    end
    context "パラメータが不正な場合" do
      it "Locationを更新できない" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        params = {
          location: {name: "", code: "test", prefix: "TST"}
        }
        patch admin_location_path(location), params: params, headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/locations/:id" do
    context "子のStockを持つ場合" do
      it "Locationを削除できない" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        stock = Stocks::Creator.call(plant: plant, location: location, growing_method: "pot", propagation_method: "seed")

        delete admin_location_path(location), headers: admin_headers
        expect(flash.now[:alert]).to include("削除に失敗しました")
      end
    end
    context "子のStockを持たない場合" do
      it "Locationを削除できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")

        delete admin_location_path(location), headers: admin_headers
        expect(response).to redirect_to(admin_locations_path)

        expect(flash[:notice]).to eq("削除しました")
      end
    end
  end
end
