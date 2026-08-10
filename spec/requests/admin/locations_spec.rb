require "rails_helper"

RSpec.describe "Admin::Locations", type: :request do
  describe "共通アクション" do
    it "一覧と作成画面で共通のコレクション操作を表示する" do
      {
        admin_locations_path => "場所一覧",
        new_admin_location_path => "場所を追加"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="場所の操作"]')
        expect(actions.text).to include("場所を追加", "場所一覧")
        expect(actions.at_css('[aria-current="page"]').text.strip).to eq(current_label)
      end
    end

    it "詳細と編集画面で共通のレコード操作を表示する" do
      location = Location.create!(name: "共通操作の場所", code: "common-actions", prefix: "CMA")

      {
        admin_location_path(location) => "詳細",
        edit_admin_location_path(location) => "編集"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="場所の操作"]')
        expect(actions.text).to include("詳細", "編集", "場所を追加", "場所一覧")
        expect(actions.at_css('input[value="削除"]')).to be_present
        expect(actions.at_css('[aria-current="page"]').text.strip).to eq(current_label)
      end
    end
  end

  # index
  describe "GET /admin/locations" do
    it "保存済みのLocationが一覧に表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")

      get admin_locations_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_admin_location_path(location))
    end
  end

  # show
  describe "GET /admin/locations/:id" do
    it "保存済みのLocation詳細が表示される" do
      location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
      get admin_location_path(location), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end

    it "ID順で前後のLocation詳細へ移動できる" do
      previous_location = Location.create!(name: "前の場所", code: "previous", prefix: "PRV")
      location = Location.create!(name: "現在の場所", code: "current", prefix: "CUR")
      next_location = Location.create!(name: "次の場所", code: "next", prefix: "NXT")

      get admin_location_path(location), headers: admin_headers

      document = Nokogiri::HTML(response.body)
      expect(document.at_css('a[rel="prev"]')["href"]).to eq(admin_location_path(previous_location))
      expect(document.at_css('a[rel="next"]')["href"]).to eq(admin_location_path(next_location))
    end
  end

  # new
  describe "GET /admin/locations/new" do
    it "新規Location作成画面が表示される" do
      get new_admin_location_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="location[image]"')
    end
  end

  # create
  describe "POST /admin/locations" do
    context "パラメータが正常な場合" do
      it "Locationを作成できる" do
        valid_params = {
          location: {
            name: "テストロケーション",
            code: "test",
            prefix: "TST",
            environment: "outdoor",
            image: fixture_file_upload(Rails.root.join("public/icon.png"), "image/png")
          }
        }

        expect {
          post admin_locations_path, params: valid_params, headers: admin_headers
        }.to change(Location, :count).by(1)

        created_location = Location.last

        # 作成値を検証
        expect(created_location.name).to eq("テストロケーション")
        expect(created_location.code).to eq("test")
        expect(created_location.prefix).to eq("TST")
        expect(created_location.environment).to eq("outdoor")
        expect(created_location.image).to be_attached

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

    it "ID順で前後のLocation編集画面へ移動できる" do
      previous_location = Location.create!(name: "前の場所", code: "previous", prefix: "PRV")
      location = Location.create!(name: "現在の場所", code: "current", prefix: "CUR")
      next_location = Location.create!(name: "次の場所", code: "next", prefix: "NXT")

      get edit_admin_location_path(location), headers: admin_headers

      document = Nokogiri::HTML(response.body)
      expect(document.at_css('a[rel="prev"]')["href"]).to eq(edit_admin_location_path(previous_location))
      expect(document.at_css('a[rel="next"]')["href"]).to eq(edit_admin_location_path(next_location))
    end
  end

  # update
  describe "PATCH /admin/locations/:id" do
    context "パラメータが正常な場合" do
      it "Locationを更新できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        params = {
          location: { name: "更新後ロケーション", code: "test", prefix: "TST" }
        }
        patch admin_location_path(location, params), headers: admin_headers
        expect(location.reload.name).to eq("更新後ロケーション")
        expect(response).to redirect_to(admin_location_path(location))
        expect(flash[:notice]).to include("更新しました")
      end
      it "Locationに更新がない" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")
        params = {
          location: { name: "テストロケーション", code: "test", prefix: "TST" }
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
          location: { name: "", code: "test", prefix: "TST" }
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
        stock = Stocks::Creator.call(plant_id: plant.id, location_id: location.id, growing_method: "pot", propagation_method: "seed")

        delete admin_location_path(location), headers: admin_headers
        expect(flash.now[:alert]).to include("削除に失敗しました")
      end
    end
    context "子のStockを持たない場合" do
      it "移動履歴から参照されるLocationを削除できない" do
        plant = Plant.create!(name: "テストプラント", code: "test", prefix: "TST")
        source = Location.create!(name: "移動元", code: "src", prefix: "SRC")
        destination = Location.create!(name: "移動先", code: "dst", prefix: "DST")
        stock = Stocks::Creator.call(
          plant_id: plant.id,
          location_id: source.id,
          growing_method: "pot",
          propagation_method: "seed"
        )
        stock.move_to!(location_id: destination.id)

        delete admin_location_path(source), headers: admin_headers

        expect(flash.now[:alert]).to include("削除に失敗しました")
      end

      it "Locationを削除できる" do
        location = Location.create!(name: "テストロケーション", code: "test", prefix: "TST")

        delete admin_location_path(location), headers: admin_headers
        expect(response).to redirect_to(admin_locations_path)

        expect(flash[:notice]).to eq("削除しました")
      end
    end
  end
end
