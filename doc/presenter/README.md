# Presenter 運用ガイド

このドキュメントでは、Viewへ表示用データを提供するPresenterの使用基準と実装ルールを定める。

## 目的

Presenterは、モデルやサービスが持つデータをViewで扱いやすい形へ変換する。

主な責務は次のとおり。

- 複数種類のデータを1つの表示形式へ統合する
- 表示順に並べ替える
- 日時、単位、ラベルなどを表示用に整形する
- View固有の解釈や表示判定をまとめる
- 複雑な表示ロジックをViewから分離し、単体テストできるようにする

## 使用基準

次のいずれかに該当する場合は、Presenterの使用を検討する。

### 複数クラスを表示用に統合する場合

独立したクラスを2種類以上扱い、Viewへ渡すために共通形式への変換、並べ替え、表示用の整形を行う場合に使用する。

単に複数クラスを参照するだけではPresenterを導入しない。View向けの統合や解釈が必要であることを判断基準とする。

`Admin::StockLogsPresenter`は、次の2種類を共通のログ形式へ統合するためPresenterを使用している。

- `StockActionLog`
- `StockObservation`

### 1クラスでも表示ロジックが複雑な場合

扱うクラスが1種類でも、次のような場合はPresenterを使用する。

- 特定のViewに限ってモデルの値へ表示上の解釈を加える
- 複数項目を組み合わせて表示データを作る
- 表示条件の判定や分岐が複雑である
- 表示ロジックを独立してテストし、継続的に保守する必要がある

単純な属性参照や短い表示処理だけでPresenterを作る必要はない。

```erb
<%= stock.code %>
<%= stock.status_i18n %>
```

## 責務の境界

Presenterは表示用データの提供に専念する。

Presenterに置くもの:

- 表示用の日時や単位の整形
- 表示ラベルへの変換
- View固有の判定
- 複数種類の表示データの統合と並べ替え

Presenterに置かないもの:

- DBへの作成、更新、削除
- トランザクションやロック
- Strong Parametersやリダイレクト
- モデル全体で常に成立すべきバリデーション
- 画面表示に依存しない業務ルール

永続化を伴う処理や複数モデルを更新する処理はサービス、モデル全体で成立すべきルールはモデル、HTTPリクエストの制御はControllerが担当する。

## 属性の公開ルール

Presenterで公開`attr_reader`を設定してよいのは、Presenterの外部利用者が表示のために参照する値だけとする。主な外部利用者はViewとする。

```ruby
class Admin::StockPresenter
  attr_reader :display_name

  def initialize(stock)
    @display_name = "#{stock.code} / #{stock.plant.name}"
  end
end
```

Viewなどの外部利用者は、公開されたreaderを通して表示用の値を参照する。

```erb
<%= presenter.display_name %>
```

Rubyでは、`private`より後に`attr_reader`を定義し、Presenter内部だけで使用する形式も取れる。

```ruby
private

attr_reader :action_logs, :observation_logs
```

ただし、このリポジトリではprivateな`attr_reader`を使用しない。Presenter内部でのみ参照する値は、インスタンス変数を直接使用する。

```ruby
def action_log_data
  @action_logs.map do |log|
    # 表示用データへ変換する
  end
end
```

これにより、Presenterの公開`attr_reader`は「Presenterの外部へ公開する表示用の値」を表すものとして解釈を統一する。

## 配置と命名

管理画面用Presenterは、名前空間とディレクトリを一致させる。

```text
app/presenters/admin/stock_logs_presenter.rb
```

```ruby
class Admin::StockLogsPresenter
end
```

`app/presenters`はRailsのautoload対象であるため、通常は`config/application.rb`への追加設定を必要としない。

## 呼び出し方

クラスメソッド`.call`を入口にする。

```ruby
@stock_logs = Admin::StockLogsPresenter.call(
  @stock.stock_action_logs,
  @stock.stock_observations
)
```

Controllerは対象データを取得してPresenterへ渡し、ViewはPresenterの返却値を表示する。

```text
Controller
  ↓ 対象データを渡す
Presenter
  ↓ 表示用データを返す
View
```

## 返却値

同じ一覧で使用するデータは、元のクラスにかかわらず同じキーを持つ形式へ変換する。

```ruby
{
  recorded_at: "2026年07月24日15時",
  label: "観察",
  data_value: "10 cm",
  memo: "新芽を確認"
}
```

並べ替えは、表示用文字列へ変換する前の`Time`や数値など、比較に適した元の値で行う。

## テスト

Presenterの単体テストは次に配置する。

```text
spec/presenters/admin/stock_logs_presenter_spec.rb
```

Presenter specでは、統合、並べ替え、整形、空データなどPresenter自身の振る舞いを確認する。

Request specでは、ControllerからPresenterを経由してViewが例外なく表示され、代表的なデータがレスポンスに含まれることを確認する。Presenter内部の並べ替えや返却形式をRequest specで重複して検証しない。

詳細は[`RSpec 基礎`](../rspec/README.md)を参照する。
