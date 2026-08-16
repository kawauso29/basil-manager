# `nursery_groups` テーブル

## 目的

Plantごとに異なる、個体管理へ切り替える鉢上げを行う前の苗を、同じ育成条件と
工程を共有する数量単位で管理するテーブルです。工程、育成方法、容器条件、場所の
いずれかが異なる苗は別のNurseryGroupとして管理します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 苗グループID |
| `production_lot_id` | `bigint` | 不可 | なし | FK | 生産ロットID |
| `location_id` | `bigint` | 不可 | なし | FK | 現在の管理場所ID |
| `stage` | `string` | 不可 | なし | なし | 現在の生産工程 |
| `growing_method` | `string` | 不可 | なし | なし | 育成方法 |
| `container_type` | `string` | 可 | `NULL` | なし | 容器種類 |
| `quantity` | `integer` | 不可 | なし | なし | 現在数量 |
| `stage_started_on` | `date` | 不可 | なし | なし | 現工程の開始日 |
| `memo` | `text` | 可 | `NULL` | なし | メモ |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `production_lot_id`、`location_id`
- `production_lot_id`、`location_id`、`stage`、`growing_method`、
  `quantity`、`stage_started_on`は必須とする
- `quantity`は0以上とする

## 関連

- `NurseryGroup belongs_to ProductionLot`
- `NurseryGroup belongs_to Location`
- `NurseryGroup has_many Stocks`（鉢上げ元としての関連）
- Stockから鉢上げ元として参照されているNurseryGroupは削除できない

## 業務ルール

- 播種では`sown`、`germinating`、`thinning`、`pot_up_ready`を順に使用する
- 挿し木では`rooting_wait`、`rooted`、`pot_up_ready`を順に使用する
- `stage`はProductionLotの`propagation_method`に合う工程でなければならない
- `growing_method`は`water`または`soil`とする
- 一部だけを次工程へ進める場合は元グループの数量を減らし、進んだ数量の
  NurseryGroupを作成する。全部を進める場合は同じNurseryGroupを更新する
- 個体管理へ切り替える鉢上げでは数量を減らし、鉢上げ数と同じ件数のStockを作成する
- 鉢上げの基準はPlantごとに異なる。鉢サイズを設定・検証する機能はv1では持たない
- 数量訂正は工程遷移と分け、訂正後の絶対値を明示して行う
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
