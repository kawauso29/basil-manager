require "rails_helper"

RSpec.describe "Admin::Stocks", type: :request do

  let(:create_plant) do
    Plant.create!(
      name: "テストプラント",
      code: "test",
      prefix: "TST"
    )
  end
  let(:create_location) do
    Location.create!(
      name: "テストロケーション",
      code: "test",
      prefix: "TST"
    )
  end
  let(:create_stock) do
    Stocks::Creator.call(
      plant_id: create_plant.id,
      location_id: create_location.id,
      growing_method: "pot",
      propagation_method: "seed"
    )
  end
  let(:create_other_stock) do
    Stocks::Creator.call(
      plant_id: create_plant.id,
      location_id: create_location.id,
      growing_method: "pot",
      propagation_method: "seed"
    )
  end
  let(:create_parent_stock) do
    parent_stock = create_stock
    child_stock = create_other_stock
    child_stock.update!(parent_stock_id: parent_stock.id)
    parent_stock
  end
  let(:create_child_stock) do
    parent_stock = create_stock
    child_stock = create_other_stock
    child_stock.update!(parent_stock_id: parent_stock.id)
    child_stock
  end
  let(:valid_params) do
    {
      stock: {
        plant_id: create_plant.id,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed"
      }
    }
  end
  let(:invalid_params) do
    {
      stock: {
        plant_id: nil,
        location_id: create_location.id,
        growing_method: "pot",
        propagation_method: "seed"
      }
    }
  end

  # index
  describe "GET /admin/stocks" do
    it "保存済みのStockが一覧に表示される" do
      stock = create_stock
      stock2 = create_stock
      get admin_stocks_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # show
  describe "GET /admin/stocks/:id" do
    context "親株である" do
      it "Stock詳細が表示される" do
        stock = create_parent_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.parent?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "親株ではない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.parent?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株である" do
      it "Stock詳細が表示される" do
        stock = create_child_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.child?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株ではない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.child?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "親株を持つ" do
      it "Stock詳細が表示される" do
        stock = create_child_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_parent?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "親株を持たない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_parent?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株を持つ" do
      it "Stock詳細が表示される" do
        stock = create_parent_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_children?).to eq(true)
        expect(response).to have_http_status(:ok)
      end
    end
    context "子株を持たない" do
      it "Stock詳細が表示される" do
        stock = create_stock
        get admin_stock_path(stock), headers: admin_headers

        expect(stock.has_children?).to eq(false)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # new
  describe "GET /admin/stocks/new" do
    it "新規Stock作成画面が表示される" do
      get new_admin_stock_path, headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # create
  describe "POST /admin/stocks" do
    context "パラメータが正常な場合" do
      it "Stockを作成できる" do

        expect {
          post admin_stocks_path, params: valid_params, headers: admin_headers
        }.to change(Stock, :count).by(1)

        created_stock = Stock.last

        # 作成値を検証
        expect(created_stock.plant.name).to eq("テストプラント")
        expect(created_stock.location.name).to eq("テストロケーション")
        expect(created_stock.growing_method).to eq("pot")
        expect(created_stock.propagation_method).to eq("seed")

        # 遷移先がshowになるかどうか
        expect(response).to redirect_to(admin_stock_path(created_stock))

        expect(flash[:notice]).to eq("作成しました")
      end
    end

    context "パラメータが不正な場合" do
      it "Stockを作成できない" do
        expect {
          post admin_stocks_path, params: invalid_params, headers: admin_headers
        }.not_to change(Stock, :count)

        expect(flash.now[:alert]).to include("作成に失敗しました")
      end
    end
  end

  # edit
  describe "GET /admin/stocks/:id/edit" do
    it "Stock編集画面が表示される" do
      stock = create_stock
      get edit_admin_stock_path(stock), headers: admin_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # update
  describe "PATCH /admin/stocks/:id" do
    context "パラメータが正常な場合" do
      it "Stockを更新できる" do
        stock = create_stock
        params = {
          stock: {growing_method: "water"}
        }
        patch admin_stock_path(stock, params), headers: admin_headers
        expect(stock.reload.growing_method).to eq("water")
        expect(response).to redirect_to(admin_stock_path(stock))
        expect(flash[:notice]).to include("更新しました")
      end
      it "Stockに更新がない" do
        stock = create_stock
        patch admin_stock_path(stock, valid_params), headers: admin_headers
        expect(stock.reload.growing_method).to eq("pot")
        expect(response).to redirect_to(admin_stock_path(stock))
        expect(flash[:notice]).to include("変更はありませんでした")
      end
    end
    context "パラメータが不正な場合" do
      it "Stockを更新できない" do
        stock = create_stock
        patch admin_stock_path(stock, invalid_params), headers: admin_headers
        expect(flash.now[:alert]).to include("更新に失敗しました")
      end
    end
  end

  # destroy
  describe "DELETE /admin/stocks/:id" do
    context "子を持つ場合" do
      it "親Stockを削除できない" do
        stock = create_parent_stock
        delete admin_stock_path(stock), headers: admin_headers
        expect(flash.now[:alert]).to include("削除に失敗しました")
      end
    end
    context "子のStockを持たない場合" do
      it "親でも子でもないStockを削除できる" do
        stock = create_stock
        delete admin_stock_path(stock), headers: admin_headers
        expect(response).to redirect_to(admin_stocks_path)
        expect(flash[:notice]).to eq("削除しました")
      end
      it "子であるStockを削除できる" do
        stock = create_child_stock
        delete admin_stock_path(stock), headers: admin_headers
        expect(response).to redirect_to(admin_stocks_path)
        expect(flash[:notice]).to eq("削除しました")
      end
    end
  end
end
