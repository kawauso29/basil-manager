require "rails_helper"

RSpec.describe "Admin::LocationObservations", type: :request do
  # index
  describe "GET /admin/location_observations" do
    it "保存済みのLocationObservationsが一覧に表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      location_obserbations = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: Time.current)
      get admin_location_observations_path
      expect(response).to have_http_status(:ok)
    end
    it "location_idで絞り込んだレコードだけが表示される" do
      target_location = Location.create!(
        name: "対象場所",
        code: "TARGET",
        prefix: "TGT"
      )
      other_location = Location.create!(
        name: "対象外場所",
        code: "OTHER",
        prefix: "OTH"
      )
      target_observation = target_location.location_observations.create!(
        weather: "sunny",
        temperature: 20.0,
        memo: "対象の観察記録",
        recorded_at: Time.current
      )
      other_observation = other_location.location_observations.create!(
        weather: "rainy",
        temperature: 15.0,
        memo: "対象外の観察記録",
        recorded_at: Time.current
      )
      get admin_location_observations_path(location_id: target_location.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target_observation.memo)
      expect(response.body).not_to include(other_observation.memo)
    end
  end

  # show
  describe "GET /admin/location_observations/:id" do
    it "indexへリダイレクトする" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      location_obserbations = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: Time.current)
      get admin_location_observation_path(location_obserbations)
      expect(response).to redirect_to(admin_location_observations_path)
    end
  end

  # new
  describe "GET /admin/location_observations/new" do
    it "新規LocationObservation作成画面が表示される" do
      get new_admin_location_observation_path
      expect(response).to have_http_status(:ok)
    end
  end

  # create
  describe "POST /admin/location_observations" do
    context "パラメータが正常な場合" do
      it "LocationObservationを作成できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        valid_params = {
          location_observation: {
            location_id: location.id,
            weather: "sunny",
            temperature: 10.0,
            memo: "test",
            recorded_at: Time.current
          }
        }
        expect {
          post admin_location_observations_path, params: valid_params
        }.to change(LocationObservation, :count).by(1)

        created_location_observation = LocationObservation.last

        # 作成値を検証
        expect(created_location_observation.weather).to eq("sunny")
        expect(created_location_observation.temperature).to eq(10.0)
        expect(created_location_observation.memo).to eq("test")

        # 遷移先がindexになるかどうか
        expect(response).to redirect_to(admin_location_observations_path)

        expect(flash[:notice]).to eq("作成しました")
      end
    end
    context "パラメータが不正な場合" do
      it "LocationObservationを作成できない" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        valid_params = {
          location_observation: {
            location_id: nil,
            weather: "sunny",
            temperature: 10.0,
            memo: "test",
            recorded_at: Time.current
          }
        }
        expect {
          post admin_location_observations_path, params: valid_params
        }.not_to change(LocationObservation, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end

  end

  # edit
  describe "GET /admin/location_observations/:id/edit" do
    it "LocationObservation編集画面が表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      location_obserbation = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: Time.current)
      get edit_admin_location_observation_path(location_obserbation)
      expect(response).to have_http_status(:ok)
    end
  end

  # update
  describe "PATCH /admin/location_observations/:id" do
    context "パラメータが正常な場合" do
      it "LocationObservationを更新できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        location_obserbation = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: Time.current)
        params = {
          location_observation: {
            location_id: location.id,
            weather: "rainy",
            temperature: 20.0,
            memo: "update",
            recorded_at: Time.current
          }
        }
        patch admin_location_observation_path(location_obserbation, params)
        expect(location_obserbation.reload.weather).to eq("rainy")
        expect(flash[:notice]).to include("更新しました")
      end
      it "LocationObservationに更新がない" do
        recorded_at = Time.current.change(usec: 0)
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        location_obserbation = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: recorded_at)
        params = {
          location_observation: {
            location_id: location.id,
            weather: "sunny",
            temperature: 10.0,
            memo: "test",
            recorded_at: recorded_at
          }
        }
        patch admin_location_observation_path(location_obserbation, params)
        expect(location_obserbation.reload.weather).to eq("sunny")
        expect(flash[:notice]).to include("変更はありませんでした")
      end
    end
    context "パラメータが不正な場合" do
      it "LocationObservationを更新できない" do
        recorded_at = Time.current.change(usec: 0)
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        location_obserbation = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: Time.current)
        params = {
          location_observation: {
            location_id: nil,
            weather: "rainy",
            temperature: 20.0,
            memo: "update",
            recorded_at: recorded_at
          }
        }
        patch admin_location_observation_path(location_obserbation, params)
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/location_observations/:id" do
    it "LocationObservationを削除" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      location_observation = location.location_observations.create!(weather: "sunny", temperature: 10.0, memo: "test", recorded_at: Time.current)

      expect {
        delete admin_location_observation_path(location_observation)
      }.to change(LocationObservation, :count).by(-1)
      expect(response).to redirect_to(admin_location_observations_path)
      expect(flash[:notice]).to include("削除しました")
    end
  end

  # bulk_new
  describe "GET /admin/location_observations/bulk_new" do
    it "LocationObservation一括作成画面が表示される" do
      get bulk_new_admin_location_observations_path
      expect(response).to have_http_status(:ok)
    end
  end

  # bulk_create
  describe "POST /admin/location_observations/bulk_create" do
    context "location_idsがある場合" do
      it "LocationObservationを一括作成できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        location2 = Location.create!(name: "テストロケーション2", code: "test2", prefix: "TST2")
        valid_params = {
          location_observation: {
            location_ids:[location.id, location2.id],
            weather: "sunny",
            temperature: 10.0,
            memo: "test",
            recorded_at: Time.current,
          }
        }
        expect {
          post bulk_create_admin_location_observations_path, params: valid_params
        }.to change(LocationObservation, :count).by(2)

        created_location_observation = LocationObservation.find_by(location_id: location.id)
        created_location_observation2 = LocationObservation.find_by(location_id: location2.id)

        # 作成値を検証
        expect(created_location_observation.location_id).to eq(location.id)
        expect(created_location_observation.weather).to eq("sunny")
        expect(created_location_observation.temperature).to eq(10.0)
        expect(created_location_observation.memo).to eq("test")

        expect(created_location_observation2.location_id).to eq(location2.id)
        expect(created_location_observation2.weather).to eq("sunny")
        expect(created_location_observation2.temperature).to eq(10.0)
        expect(created_location_observation2.memo).to eq("test")

        # 遷移先がindexになるかどうか
        expect(response).to redirect_to(admin_location_observations_path)

        expect(flash[:notice]).to eq("作成しました")
      end
    end
    context "location_idsがない場合" do
      it "LocationObservationを一括作成できない" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        valid_params = {
          location_observation: {
            location_ids: [],
            weather: "sunny",
            temperature: 10.0,
            memo: "test",
            recorded_at: Time.current,
          }
        }
        expect {
          post bulk_create_admin_location_observations_path, params: valid_params
        }.not_to change(LocationObservation, :count)

        expect(flash.now[:alert]).to eq("location_idがありません")
      end
    end
  end
end