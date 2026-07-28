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
| `from_location_id` | `bigint` | 可 | なし | FK | 移動前の管理場所ID |
| `to_location_id` | `bigint` | 可 | なし | FK | 移動後の管理場所ID |
| `quantity_before` | `integer` | 可 | なし | なし | 数量変更前の株数 |
| `quantity_after` | `integer` | 可 | なし | なし | 数量変更後の株数 |
| `status_before` | `string` | 可 | なし | なし | 状態変更前の管理状態 |
| `status_after` | `string` | 可 | なし | なし | 状態変更後の管理状態 |
| `memo` | `text` | 可 | `NULL` | なし | 作業に関する補足 |
| `recorded_at` | `datetime` | 可 | `NULL` | なし | 作業を実施した日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `stock_id`、`from_location_id`、`to_location_id`
- `stock_id`、`action_type`は必須とする

## 関連

- `StockActionLog belongs_to Stock`
- `StockActionLog belongs_to FromLocation`（任意）
- `StockActionLog belongs_to ToLocation`（任意）
- `stocks.id`を`stock_id`で参照する

## 業務ルール

- 作業が行われた日時は`created_at`ではなく`recorded_at`に記録する
- 日時が未確定の場合は`recorded_at`を空にして作成し、後から入力できる
- 作業の種類は`action_type`で識別し、詳細が必要な場合は`memo`に記録する
- `action_type`は`seed_sown`、`cutting_started`、`watered`、`fertilized`、
  `pinched`、`pruned`、`water_replaced`、`harvested`、`moved`、
  `status_changed`、`transplanted`、`quantity_changed`のいずれかとする
- `moved`、`status_changed`、`quantity_changed`はStockの専用操作から作成する。
  通常の作業ログ作成画面では選択しない
- `moved`は`from_location_id`と`to_location_id`、`status_changed`は
  `status_before`と`status_after`、`quantity_changed`は`quantity_before`と
  `quantity_after`を必ず記録する
- これらの専用操作は、Stockの現在値更新とログ作成を同一トランザクションで行う
- 一括記録画面では、`Location.environment`と複数のLocationで育成中のStockを
  絞り込み、対象のStockを個別に選択する。Locationが未選択の場合は、
  指定した環境の全Locationを対象にする
- 一括記録では、選択したStockごとに同じ`action_type`、`memo`、`recorded_at`を持つ
  `stock_action_logs`を1件ずつ作成する。各Stockの履歴は既存の関連から確認できる
- `moved`、`status_changed`、`quantity_changed`は現在値の更新を伴うため、一括記録の
  `action_type`には使用しない
- 一括記録の対象は育成中かつ指定した環境・Locationに一致するStockに限り、
  画面の絞り込みとは別にサーバー側でも検証する
- 一括作成はトランザクション内で行い、1件でも保存に失敗した場合は全件をロールバックする
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
