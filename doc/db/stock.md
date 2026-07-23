# `stocks` テーブル

## 目的

個別の株または栽培単位を管理するテーブルです。
植物の種類、現在の保管場所、状態、栽培方法、増殖元を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 株ID |
| `plant_id` | `bigint` | 不可 | なし | FK | 植物ID |
| `location_id` | `bigint` | 不可 | なし | FK | 現在の保管場所ID |
| `parent_stock_id` | `bigint` | 可 | `NULL` | FK | 増殖元となった株ID |
| `public_token` | `string` | 不可 | なし | UK | 公開画面で株を識別するトークン |
| `code` | `string` | 可 | `NULL` | なし | 株の管理名 |
| `status` | `string` | 不可 | なし | なし | 現在の管理状態 |
| `growing_method` | `string` | 不可 | なし | なし | 栽培方法 |
| `propagation_method` | `string` | 不可 | なし | なし | 増殖方法 |
| `completion_reason` | `string` | 可 | `NULL` | なし | 育成完了理由 |
| `completed_at` | `datetime` | 可 | `NULL` | なし | 育成完了日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `public_token`
- インデックス: `plant_id`、`location_id`、`parent_stock_id`
- `status`、`growing_method`、`propagation_method`は必須とする
- `parent_stock_id`には自身の`id`を指定できない

## 関連

- `Stock belongs_to Plant`
- `Stock belongs_to Location`
- `Stock belongs_to ParentStock`（任意）
- `Stock has_many ChildStocks`
- `Stock has_many StockActionLogs`
- `Stock has_many StockObservations`

## 業務ルール

- 各株は、植物の種類と現在の保管場所を1件ずつ持つ
- 増殖元がある場合は`parent_stock_id`で元の株を参照する
- 外部公開時は連番の`id`ではなく`public_token`を使用する
- 状態の履歴は`stock_action_logs`、観察値は`stock_observations`に記録する
- `status`は`starting`、`rooting`、`growing`のいずれかとする
- `growing_method`は`pot`、`planter`、`water`のいずれかとする
- `propagation_method`は`cutting_soil`、`cutting_water`、`seed`のいずれかとする
- `completion_reason`は未設定、`cultivation_ended`、`harvested`、`discarded`のいずれかとする
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
