# `production_lots` テーブル

## 目的

同じ生産開始イベントから生まれた苗群の出自と開始条件を管理するテーブルです。
同じLot内でも苗ごとに進行速度が異なるため、現在工程や現在数量は保持しません。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 生産ロットID |
| `plant_id` | `bigint` | 不可 | なし | FK | 対象植物ID |
| `source_stock_id` | `bigint` | 可 | `NULL` | FK | 挿し穂を採取した親Stock ID |
| `propagation_method` | `string` | 不可 | なし | なし | 生産方法 |
| `started_on` | `date` | 不可 | なし | なし | 生産開始日 |
| `initial_quantity` | `integer` | 不可 | なし | なし | 開始数量 |
| `memo` | `text` | 可 | `NULL` | なし | メモ |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `plant_id`、`source_stock_id`
- `plant_id`、`propagation_method`、`started_on`、`initial_quantity`は必須とする
- `initial_quantity`は1以上とする

## 関連

- `ProductionLot belongs_to Plant`
- `ProductionLot belongs_to SourceStock`（任意）
- `ProductionLot has_many NurseryGroups`
- `ProductionLot has_many Stocks through NurseryGroups`
- NurseryGroupから参照されているProductionLotは削除できない

## 業務ルール

- `propagation_method`は`seed`または`cutting`とする
- `source_stock_id`を設定する場合は、親Stockと同じPlantでなければならない
- 播種の初期工程は`sown`、挿し木の初期工程は`rooting_wait`とする
- Plantで品種を区別するため、ProductionLotには品種名を重複保持しない
- Lot全体の現在工程や単一の発根日時は持たない
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
