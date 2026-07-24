# RSpec 基礎

このドキュメントでは、`spec/requests/admin/plants_spec.rb` を例に、RSpecでRailsの管理画面をテストするための基本を説明する。

## ファイル構成

```text
.rspec                         # RSpecコマンドの標準オプション
spec/
├── requests/                  # HTTPリクエストを通したテスト
│   └── admin/
│       └── plants_spec.rb
├── spec_helper.rb             # Railsに依存しないRSpec全体の設定
└── rails_helper.rb            # Rails、DB、ルートを使うテストの設定
```

Railsのモデル、DB、ルート、Controllerを使うspecでは、先頭で `rails_helper` を読み込む。

```ruby
require "rails_helper"
```

## 実行環境

RSpecはdevelopment DBではなく、test DBで実行する。

```text
development: basil_manager_development  # ブラウザでの手動確認用
test:        basil_manager_test         # RSpecによる自動テスト用
```

コンテナ内から全specを実行する。

```bash
RAILS_ENV=test bundle exec rspec
```

PlantのRequest specだけを実行する。

```bash
RAILS_ENV=test bundle exec rspec spec/requests/admin/plants_spec.rb
```

特定の行にあるexampleだけを実行することもできる。

```bash
RAILS_ENV=test bundle exec rspec spec/requests/admin/plants_spec.rb:35
```

成功時の出力例は次のとおり。`.` は成功したexampleを表す。

```text
...........

11 examples, 0 failures
```

## Request specの基本構造

```ruby
RSpec.describe "Admin::Plants", type: :request do
  describe "GET /admin/plants" do
    it "保存済みのPlantが一覧に表示される" do
      get admin_plants_path

      expect(response).to have_http_status(:ok)
    end
  end
end
```

### `RSpec.describe`

spec全体のテスト対象を表す。

```ruby
RSpec.describe "Admin::Plants", type: :request do
```

`type: :request` を指定すると、`get`、`post`、`patch`、`delete`、`response` など、RailsのHTTPリクエスト用機能を利用できる。

### `describe`

テストする機能やHTTPエンドポイントをまとめる。

```ruby
describe "POST /admin/plants" do
```

### `context`

同じ機能を前提条件ごとに分ける。

```ruby
context "パラメータが正常な場合" do
end

context "パラメータが不正な場合" do
end
```

### `it`

期待する振る舞いを1つのexampleとして記述する。DBレコードの作成やHTTPリクエストは、原則として `it` の中で実行する。

```ruby
it "Plantを作成できる" do
  # 準備、実行、確認を書く
end
```

`describe` や `context` の直下で `Plant.create!` すると、specファイルを読み込んだ時点で実行される。そのデータはexample用トランザクションの対象外になり、test DBに残る可能性があるため避ける。

## `let`によるテストデータの共通化

複数のexampleで同じテストデータを使う場合は、`let`で準備処理を共通化できる。

```ruby
RSpec.describe "Admin::Stocks", type: :request do
  let(:plant) do
    Plant.create!(
      name: "テストプラント",
      code: "test",
      prefix: "TST"
    )
  end

  let(:location) do
    Location.create!(
      name: "テストロケーション",
      code: "test",
      prefix: "TST"
    )
  end

  let(:stock) do
    Stocks::Creator.call(
      plant_id: plant.id,
      location_id: location.id,
      growing_method: "pot",
      propagation_method: "seed"
    )
  end
end
```

example内では、定義した名前をメソッドのように呼び出す。

```ruby
it "Stock詳細が表示される" do
  get admin_stock_path(stock), headers: admin_headers

  expect(response).to have_http_status(:ok)
end
```

### 遅延評価

`let`は、定義した場所ですぐに実行されるわけではない。各exampleで初めて呼び出されたときに実行され、同じexample内ではその結果が再利用される。

```ruby
let(:stock) { Stocks::Creator.call(...) }

it "Stockを使用する" do
  stock # ここで初めてStockが作成される
  stock # 作り直さず、同じStockが返る
end

it "Stockを使用しない" do
  # stockを呼んでいないため、Stockは作成されない
end
```

Stockの新規作成を確認するexampleでは、既存の `stock` を呼ばずにリクエストを実行する。先に `stock` を呼ぶと、件数確認の前にStockが1件作成されるため注意する。

```ruby
let(:valid_params) do
  {
    stock: {
      plant_id: plant.id,
      location_id: location.id,
      growing_method: "pot",
      propagation_method: "seed"
    }
  }
end

it "Stockを作成できる" do
  expect {
    post admin_stocks_path,
         params: valid_params,
         headers: admin_headers
  }.to change(Stock, :count).by(1)
end
```

### `let!`との違い

`let!`は遅延評価ではなく、各exampleの開始前に必ず実行される。

```ruby
let!(:stock) do
  Stocks::Creator.call(
    plant_id: plant.id,
    location_id: location.id,
    growing_method: "pot",
    propagation_method: "seed"
  )
end
```

一覧画面のように「リクエスト前から必ずStockが存在する」という前提を明示したい場合には使える。ただし、Stockを必要としないexampleでも作成されるため、通常は `let`を優先する。

### `before`との使い分け

`before`は、各exampleの前に共通の処理を実行したい場合に使用する。

```ruby
before do
  get admin_stocks_path, headers: admin_headers
end
```

モデルなどの値を準備してexampleから参照したい場合は `let`、HTTPリクエストなどの共通処理を事前実行したい場合は `before`を使うと役割が分かりやすい。

`let`、`let!`、`before`で作成されたDBレコードも、各exampleのトランザクション内で作成されるため、example終了後にロールバックされる。

## テストの組み立て方

1つのexampleは、次の3段階で考える。

```text
準備（Arrange）
  ↓
実行（Act）
  ↓
確認（Assert）
```

Plant作成の例では、次のようになる。

```ruby
it "Plantを作成できる" do
  # 準備
  valid_params = {
    plant: { name: "テストプラント", code: "test", prefix: "TST" }
  }

  # 実行と件数の確認
  expect {
    post admin_plants_path, params: valid_params
  }.to change(Plant, :count).by(1)

  # 保存結果の確認
  created_plant = Plant.last
  expect(created_plant.name).to eq("テストプラント")

  # HTTPレスポンスの確認
  expect(response).to redirect_to(admin_plant_path(created_plant))
  expect(flash[:notice]).to eq("作成しました")
end
```

## HTTPリクエスト

Request specでは、Railsのルートヘルパーを使ってリクエストを送る。

```ruby
get admin_plants_path
get admin_plant_path(plant)
post admin_plants_path, params: params
patch admin_plant_path(plant), params: params
delete admin_plant_path(plant)
```

HTTPメソッドとControllerアクションの対応は次のとおり。

| HTTPメソッド | パス | Controllerアクション | 主な役割 |
|---|---|---|---|
| GET | `/admin/plants` | `index` | 一覧表示 |
| GET | `/admin/plants/:id` | `show` | 詳細表示 |
| GET | `/admin/plants/new` | `new` | 作成フォーム表示 |
| POST | `/admin/plants` | `create` | 新規作成 |
| GET | `/admin/plants/:id/edit` | `edit` | 編集フォーム表示 |
| PATCH | `/admin/plants/:id` | `update` | 更新 |
| DELETE | `/admin/plants/:id` | `destroy` | 削除 |

### パラメータの形

Controllerが次のStrong Parametersを使っている場合、送信値は `plant` の下へネストする。

```ruby
params.require(:plant).permit(:name, :code, :prefix)
```

Request specから送る値も同じ形にする。

```ruby
params = {
  plant: {
    name: "テストプラント",
    code: "test",
    prefix: "TST"
  }
}

post admin_plants_path, params: params
```

## `response`

`response` は変数ではなく、直前のHTTPリクエスト結果を返すメソッドである。

```ruby
get admin_plants_path

expect(response).to have_http_status(:ok)
```

次のリクエストを実行すると、`response` もそのリクエストの結果へ切り替わる。

## `expect` とmatcher

RSpecでは、期待する結果を次の形で記述する。

```ruby
expect(実際の値).to matcher(期待値)
```

### 値の一致

```ruby
expect(created_plant.name).to eq("テストプラント")
```

`eq` は値が等しいことを確認する。

### 文字列を含むこと

```ruby
expect(flash[:alert]).to include("作成に失敗しました")
```

`include` は、文字列や配列に指定した内容が含まれることを確認する。

### HTTPステータス

```ruby
expect(response).to have_http_status(:ok)
```

`:ok` はHTTPステータス200を表す。バリデーション失敗を `render` する場合は、422を確認する。

```ruby
expect(response).to have_http_status(:unprocessable_content)
```

### リダイレクト先

```ruby
expect(response).to redirect_to(admin_plant_path(plant))
```

レスポンスが指定したパスへのリダイレクトになっていることを確認する。

## `change`

`change` は、ブロック実行前後の値の変化を確認するmatcherである。

```ruby
expect {
  post admin_plants_path, params: valid_params
}.to change(Plant, :count).by(1)
```

処理の流れは次のとおり。

```text
POST前のPlant.countを取得
  ↓
POSTを実行
  ↓
POST後のPlant.countを取得
  ↓
差が+1であることを確認
```

削除によって1件減ることを確認する場合は `by(-1)` を使う。

```ruby
expect {
  delete admin_plant_path(plant)
}.to change(Plant, :count).by(-1)
```

件数が変化しないことを確認する場合は `not_to change` を使う。

```ruby
expect {
  post admin_plants_path, params: invalid_params
}.not_to change(Plant, :count)
```

## `reload`

HTTPリクエストによってDBが更新されても、spec内のRubyオブジェクトは更新前の属性を持っていることがある。`reload` を使うとDBから最新状態を読み直せる。

```ruby
patch admin_plant_path(plant), params: {
  plant: { name: "更新後プラント" }
}

expect(plant.reload.name).to eq("更新後プラント")
```

## flashの確認

成功してリダイレクトする処理では、通常のflashを確認する。

```ruby
expect(flash[:notice]).to eq("作成しました")
```

バリデーションに失敗して同じフォームを `render` する処理では、Controller側で `flash.now` を使用する。

```ruby
flash.now[:alert] = "作成に失敗しました"
render :new, status: :unprocessable_content
```

Request specでは、flashオブジェクトとレスポンス本文を確認できる。

```ruby
expect(flash[:alert]).to include("作成に失敗しました")
expect(response.body).to include("作成に失敗しました")
```

使い分けは次のとおり。

```text
redirect_to + flash
render      + flash.now + HTTP 422
```

## test DBとトランザクション

`spec/rails_helper.rb` では、各exampleをトランザクション内で実行する設定になっている。

```ruby
config.use_transactional_fixtures = true
```

`it` の中で作成したレコードは、example終了後にロールバックされる。

```text
it開始
  ↓
Plant.create!
  ↓
expectで確認
  ↓
it終了
  ↓
ROLLBACK
```

そのため、各exampleは必要なデータを自分で準備し、別のexampleが作ったデータへ依存させない。

## Request specとModel specの分担

Request specでは、HTTPリクエストを通した機能全体を確認する。

```text
正常なパラメータで作成できる
不正なパラメータでは作成されない
正しい画面へリダイレクトする
flashが設定される
```

Model specでは、モデル自身のルールを確認する。

```text
nameが空なら無効
codeが空なら無効
prefixが空なら無効
codeが重複したら無効
Stockを持つPlantは削除できない
```

全バリデーションをRequest specでも繰り返す必要はない。Request specでは代表的な不正入力を1ケース確認し、個別のバリデーションはModel specで確認する。

## Plant管理画面で保証している内容

`spec/requests/admin/plants_spec.rb` は、次の振る舞いを対象としている。

- 一覧、詳細、新規作成、編集画面へアクセスできる
- 正常なパラメータでPlantを作成できる
- 不正なパラメータではPlantを作成できない
- Plantを更新できる
- 値が変わらない更新を処理できる
- 不正なパラメータではPlantを更新できない
- Stockを持たないPlantを削除できる
- Stockを持つPlantは削除できない

HTTPステータスだけを確認するテストは、「画面で例外が発生しないこと」を保証する。実際にPlantの名前などが表示されることまで保証したい場合は、レスポンス本文も確認する。

```ruby
expect(response.body).to include(plant.name)
```

テスト名と実際のexpectationが同じ振る舞いを確認しているかを意識する。
