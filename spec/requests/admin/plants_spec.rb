require "rails_helper"

RSpec.describe "Admin::Plants", type: :request do
  describe "共通アクション" do
    it "一覧と作成画面で共通のコレクション操作を表示する" do
      {
        admin_plants_path => "植物一覧",
        new_admin_plant_path => "植物を追加"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="植物の操作"]')
        expect(actions.text).to include("植物を追加", "植物一覧")
        expect(actions.at_css('[aria-current="page"]').text.strip).to eq(current_label)
      end
    end

    it "詳細と編集画面で共通のレコード操作を表示する" do
      plant = Plant.create!(name: "共通操作の植物", code: "common-actions", prefix: "CMA")

      {
        admin_plant_path(plant) => "詳細",
        edit_admin_plant_path(plant) => "編集"
      }.each do |path, current_label|
        get path, headers: admin_headers

        actions = Nokogiri::HTML(response.body).at_css('[aria-label="植物の操作"]')
        expect(actions.text).to include("詳細", "編集", "植物を追加", "植物一覧")
        expect(actions.at_css('input[value="削除"]')).to be_present
        expect(actions.at_css('[aria-current="page"]').text.strip).to eq(current_label)
      end
    end
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
        scientific_name: "Ocimum basilicum"
      )
      get admin_plant_path(plant), headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ocimum basilicum")
    end

    it "ID順で前後のPlant詳細へ移動できる" do
      previous_plant = Plant.create!(name: "前の植物", code: "previous", prefix: "PRV")
      plant = Plant.create!(name: "現在の植物", code: "current", prefix: "CUR")
      next_plant = Plant.create!(name: "次の植物", code: "next", prefix: "NXT")

      get admin_plant_path(plant), headers: admin_headers

      document = Nokogiri::HTML(response.body)
      expect(document.at_css('a[rel="prev"]')["href"]).to eq(admin_plant_path(previous_plant))
      expect(document.at_css('a[rel="next"]')["href"]).to eq(admin_plant_path(next_plant))
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
            scientific_name: "Ocimum basilicum",
            image: fixture_file_upload(Rails.root.join("public/icon.png"), "image/png")
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
        expect(created_plant.scientific_name).to eq("Ocimum basilicum")
        expect(created_plant.image).to be_attached

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_plant_path(created_plant))

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

    it "ID順で前後のPlant編集画面へ移動できる" do
      previous_plant = Plant.create!(name: "前の植物", code: "previous", prefix: "PRV")
      plant = Plant.create!(name: "現在の植物", code: "current", prefix: "CUR")
      next_plant = Plant.create!(name: "次の植物", code: "next", prefix: "NXT")

      get edit_admin_plant_path(plant), headers: admin_headers

      document = Nokogiri::HTML(response.body)
      expect(document.at_css('a[rel="prev"]')["href"]).to eq(edit_admin_plant_path(previous_plant))
      expect(document.at_css('a[rel="next"]')["href"]).to eq(edit_admin_plant_path(next_plant))
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
            scientific_name: "Ocimum basilicum"
          }
        }
        patch admin_plant_path(plant, params), headers: admin_headers
        expect(plant.reload.name).to eq("更新後プラント")
        expect(plant.scientific_name).to eq("Ocimum basilicum")
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
