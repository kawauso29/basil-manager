# enum 運用ガイド

このドキュメントでは、basil-managerにおけるRails enumと`enum_help`の
定義・表示・変更・テスト方法を説明します。

## 基本方針

- enumのDBカラムには英語の`snake_case`文字列を保存する
- enumは配列形式ではなく、保存値を明記したハッシュ形式で定義する
- 日本語表示はモデル定数に持たず、`enum_help`と`config/locales/ja.yml`で管理する
- 必須属性には`validate: true`を指定する
- 空を許可する属性に限り`validate: { allow_blank: true }`を指定する
- `allow_blank`はDBカラムがNULLを許可し、業務上も未設定を許可する場合だけ使用する
- 一度利用を開始した保存値は外部インターフェースとして扱い、データ移行なしに変更しない

## enumの定義

必須属性は、次のように定義します。

```ruby
enum :status, {
  starting: "starting",
  rooting: "rooting",
  growing: "growing"
}, validate: true
```

未定義値は代入時の例外ではなく、モデルのバリデーションエラーとして扱われます。

```ruby
stock.status = "unknown"
stock.valid? # => false
stock.errors.details[:status]
# => [{ error: :inclusion, value: "unknown" }]
```

空を許可する属性は、次のように定義します。

```ruby
enum :completion_reason, {
  cultivation_ended: "cultivation_ended",
  harvested: "harvested",
  discarded: "discarded"
}, validate: { allow_blank: true }
```

`completion_reason`は育成完了前には未設定となるため、空を許可します。
一方、`status`、`growing_method`、`propagation_method`、
`StockActionLog#action_type`、`Location#environment`などの必須属性には
`allow_blank`を付けません。

## enumの利用

enumには値の取得・判定・更新・検索用のメソッドが生成されます。

```ruby
stock.status = :starting
stock.status       # => "starting"
stock.starting?    # => true
stock.growing!     # statusを"growing"へ更新して保存
Stock.starting     # statusが"starting"のStockを検索
Stock.statuses     # enumの保存値一覧
```

コードから値を渡す場合は、モデル定数の表示名ではなくenumキーを使用します。

```ruby
Stock.create!(status: :starting)
```

## enum_helpによる日本語表示

`enum_help`はenumの値に対応する表示名をI18nから取得します。
翻訳は`config/locales/ja.yml`の`ja.enums`配下に定義します。

```yaml
ja:
  enums:
    stock:
      status:
        starting: 育成開始
        rooting: 発根中
        growing: 生育中
```

インスタンスでは、属性名に`_i18n`を付けて表示名を取得します。

```ruby
stock.status       # => "starting"
stock.status_i18n  # => "育成開始"
```

クラスでは、enum属性名を複数形にしたメソッドで表示名一覧を取得します。

```ruby
Stock.statuses_i18n
# => { "starting" => "育成開始", "rooting" => "発根中", ... }

Stock.completion_reasons_i18n
Stock.growing_methods_i18n
Stock.propagation_methods_i18n
StockActionLog.action_types_i18n
Location.environments_i18n
LocationObservation.weathers_i18n
```

Gemの追加やenum定義の変更後に`*_i18n`メソッドが見つからない場合は、
Railsサーバーを再起動します。

## フォームと画面表示

画面には`*_i18n`の表示名を出し、フォームからは英語のenumキーを送信します。

```ruby
@status_options = Stock.statuses_i18n.map do |value, label|
  [label, value]
end
```

```erb
<%= f.select :status, @status_options, prompt: "選択してください" %>
```

一覧や詳細では、保存値ではなく翻訳済みの値を表示します。

```erb
<%= stock.status_i18n %>
```

## DB制約と一括更新

`validate: true`はRailsモデル経由の`save`、`create`、`update`に適用されます。
DBにCHECK制約を追加するものではありません。

`insert_all`、`update_all`、直接SQLはモデルバリデーションを通らないため、
未定義値を保存できる可能性があります。enum値を含む一括処理でモデルの
バリデーションが必要な場合は、トランザクション内で`create!`や`update!`を
使用します。

```ruby
Stock.transaction do
  attributes_list.each do |attributes|
    Stock.create!(attributes)
  end
end
```

高速な一括処理として`insert_all`を採用する場合は、呼び出し側で値を検証し、
必要に応じてDBのCHECK制約も検討します。

## enum値の追加・変更

enum値を追加するときは、次を同じ変更に含めます。

1. モデルのenum定義へ保存値を追加する
2. `config/locales/ja.yml`へ日本語表示を追加する
3. フォーム、サービス、テストでモデル定数や自由入力文字列を使っていないか確認する
4. `doc/db/<table>.md`の許容値を更新する
5. enum値・日本語表示・未定義値のテストを追加または更新する

既存値の名前変更や削除では、先にDB内の値を確認します。

```ruby
Stock.group(:status).count
```

既存レコードがある場合は、旧値を新値へ変換するデータmigrationを用意します。
モデル定義だけを先に変更すると、旧値をenumとして読み取れなくなるため避けます。

## テスト

少なくとも次の振る舞いを確認します。

- enumキーが意図した文字列として扱われる
- `*_i18n`が意図した日本語表示を返す
- 必須属性では空値と未定義値を拒否する
- 空を許可する属性では空値を許可し、未定義値は拒否する
- enumを受け取るフォームやサービスが英語のenumキーを渡している

未定義値の検証では、翻訳文言に依存せずエラー種別を確認できます。

```ruby
stock = Stock.new(status: "unknown")
stock.valid?

expect(stock.errors.details[:status])
  .to include(error: :inclusion, value: "unknown")
```
