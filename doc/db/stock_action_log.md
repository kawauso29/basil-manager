# `stock_action_logs` テーブル

## 目的

株に対して行った作業や状態変更を時系列で記録するテーブルです。
現在値を持つ`stocks`とは分けて、いつ何を行ったかを保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 作業ログID |
| `stock_id` | `bigint` | 不可 | なし | FK | 対象の株ID |
| `action_type` | `string` | 不可 | なし | なし | 作業または状態変更の種類 |
| `memo` | `string` | 可 | `NULL` | なし | 作業に関する補足 |
| `recorded_at` | `datetime` | 不可 | なし | なし | 作業を実施または記録した日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `stock_id`
- `stock_id`、`action_type`、`recorded_at`は必須とする

## 関連

- `StockActionLog belongs_to Stock`
- `stocks.id`を`stock_id`で参照する

## 業務ルール

- 作業が行われた日時は`created_at`ではなく`recorded_at`に記録する
- 作業の種類は`action_type`で識別し、詳細が必要な場合は`memo`に記録する
- `action_type`は`seed_sown`、`cutting_started`、`watered`、`fertilized`、
  `pinched`、`pruned`、`water_replaced`、`harvested`、`moved`、
  `transplanted`のいずれかとする
- 株の現在状態を変更する作業では、`stocks.status`との整合性を保つ
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
