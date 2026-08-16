# `plants` テーブル

## 目的

管理対象となる植物・品種を保持するマスターテーブルです。
品種を区別して管理するときは、品種ごとにPlantを作成します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 植物ID |
| `code` | `string` | 不可 | なし | UK | 植物を一意に識別するコード |
| `name` | `string` | 不可 | なし | UK | 表示用の植物・品種名 |
| `scientific_name` | `string` | 可 | `NULL` | なし | 学名 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `code`、`name`
- `code`、`name`は必須とする

## 関連

- `Plant has_one_attached Image`
- `Plant has_many ProductionLots`
- `Plant has_many Stocks`
- ProductionLotまたはStockから参照されているPlantは削除できない

## 業務ルール

- 同じ`code`または`name`を持つ植物は重複登録できない
- 生産の出自と開始条件はProductionLotで管理する
- 鉢上げ前の現在工程と数量はNurseryGroupで管理する
- 生産由来では、Plantごとに異なる、個体管理へ切り替える鉢上げ後に
  1株を1件のStockとして管理する
- 購入・譲受した株はProductionLotとNurseryGroupを介さずStockへ直接登録できる
- 鉢サイズを設定・検証する機能はv1では持たない
