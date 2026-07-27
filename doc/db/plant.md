# `plants` テーブル

## 目的

管理対象となる植物の種類を保持するマスターテーブルです。
個別の株や栽培単位は`stocks`テーブルで管理し、`plants`にはそれらに
共通する植物名、識別コード、生育条件とお手入れの目安を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 植物ID |
| `code` | `string` | 不可 | なし | UK | 植物を一意に識別するコード |
| `prefix` | `string` | 不可 | なし | UK | 株コードに使用するプレフィックス |
| `name` | `string` | 不可 | なし | UK | 表示用の植物名 |
| `last_stock_number` | `integer` | 可 | `0` | なし | 最後に発行した株番号 |
| `scientific_name` | `string` | 可 | なし | なし | 品種の特定に使う学名 |
| `temperature_requirements` | `text` | 可 | なし | なし | 生育適温、耐暑・耐寒温度など |
| `climate_requirements` | `text` | 可 | なし | なし | 好む気候、湿度、雨への強さなど |
| `growing_season` | `text` | 可 | なし | なし | 植え付け、生育、開花、収穫、休眠の時期 |
| `sunlight_requirements` | `text` | 可 | なし | なし | 日照時間と季節ごとの遮光の目安 |
| `watering_guide` | `text` | 可 | なし | なし | 乾きの判断、季節ごとの頻度、与え方 |
| `fertilizing_guide` | `text` | 可 | なし | なし | 肥料の種類、時期、頻度 |
| `ventilation_requirements` | `text` | 可 | なし | なし | 置き場所、株間、蒸れ対策 |
| `soil_requirements` | `text` | 可 | なし | なし | 水はけ、保水性、pHなどの用土条件 |
| `pruning_guide` | `text` | 可 | なし | なし | 摘芯、剪定、切り戻しの時期と方法 |
| `overwintering_guide` | `text` | 可 | なし | なし | 冬の置き場所、温度、水・肥料の管理 |
| `care_notes` | `text` | 可 | なし | なし | 収穫や回復手順などの補足 |
| `care_cautions` | `text` | 可 | なし | なし | 根腐れ、病害虫、作業上の注意 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `code`、`prefix`、`name`
- `code`、`prefix`、`name`は必須とする

## 関連

- `Plant has_one_attached Image`
- `Plant has_many Stocks`
- `stocks.plant_id`から参照される
- Stockが存在するPlantは削除できない

## 業務ルール

- 同じ`code`を持つ植物は重複登録できない
- 同じ`prefix`または`name`を持つ植物は重複登録できない
- 個別の株の状態、栽培方法、増殖方法は`plants`ではなく`stocks`で管理する
- 生育条件は同じ種類の株で共通する標準的な目安とし、個別の株の状態や
  実施した水やり・施肥・剪定はStockの観察記録・作業履歴で管理する
- 水やりは固定の頻度だけでなく、土や鉢の乾きを判断する基準も記録する
- 品種、鉢の大きさ、管理場所、天候による差があるため、生育条件の各項目は
  NULLを許可し、確認できた項目から登録する
- `last_stock_number`は株コードの採番に使用し、通常の編集画面では変更しない

## 既存データへの登録

`db/data/20260727_update_plant_care_guides.rb`は、2026年7月27日の本番CSVで
確認した15種類を`code`で特定し、各生育条件を上書きする。何度実行しても
同じ内容になり、CSV上のIDには依存しない。

```ruby
load "db/data/20260727_update_plant_care_guides.rb"
```

記載内容は日本の平地での鉢植えを主な基準とする。水やりは固定日数より
実際の土・鉢の乾きを優先し、管理場所や個体の記録と併せて判断する。

## 未確定事項

- ローズマリー、タイム、オレガノ、ひまわりなど、CSVの名称だけでは
  園芸品種まで特定できない植物がある
- 現在のガイドは一般的な食用品種または代表種を基準とし、品種が判明した
  場合は学名と耐寒・耐暑性、剪定方法を見直す
