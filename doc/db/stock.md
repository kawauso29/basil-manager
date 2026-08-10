# `stocks` テーブル

## 目的

個々の株を管理するテーブルです。1件のStockが1株を表し、植物の種類、
現在の保管場所、状態、栽培方法を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 株ID |
| `plant_id` | `bigint` | 不可 | なし | FK | 植物ID |
| `location_id` | `bigint` | 不可 | なし | FK | 現在の保管場所ID |
| `public_token` | `string` | 不可 | なし | UK | 公開画面で株を識別するトークン |
| `code` | `string` | 不可 | なし | UK | 株の管理コード |
| `status` | `string` | 不可 | なし | なし | 現在の管理状態 |
| `growing_method` | `string` | 不可 | なし | なし | 栽培方法 |
| `propagation_method` | `string` | 可 | `NULL` | なし | 増殖方法 |
| `memo` | `text` | 可 | `NULL` | なし | 株の現在の補足 |
| `completion_reason` | `string` | 可 | `NULL` | なし | 育成完了理由 |
| `completed_at` | `datetime` | 可 | `NULL` | なし | 育成完了日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `public_token`、`code`
- インデックス: `plant_id`、`location_id`
- `plant_id`、`location_id`、`code`、`public_token`、`status`、
  `growing_method`は必須とする

## 関連

- `Stock belongs_to Plant`
- `Stock belongs_to Location`
- `Stock has_many StockActionLogs`
- `Stock has_many StockObservations`
- Stockを削除した場合は、関連するStockActionLogとStockObservationも削除する

## 業務ルール

- 1件のStockは1株を表す
- 各Stockは、植物の種類と現在の保管場所を1件ずつ持つ
- `memo`には株の現在の補足を記録する。作業時点の履歴は
  `stock_action_logs.memo`へ記録する
- 場所と状態の変更は専用操作を使用し、変更前後の値を
  `stock_action_logs`へ構造化して記録する
- 外部公開時は連番の`id`ではなく`public_token`を使用する
- 状態の履歴は`stock_action_logs`、観察値は`stock_observations`に記録する
- `status`は`starting`、`rooting`、`growing`のいずれかとする
- `growing_method`は`pot`、`planter`、`flowerpot`、`seeding_tray`、`water`、
  `other`のいずれかとする
- `propagation_method`は未設定、`cutting_soil`、`cutting_water`、`seed`の
  いずれかとする
- `completion_reason`は未設定、`cultivation_ended`、`harvested`、`discarded`の
  いずれかとする
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
