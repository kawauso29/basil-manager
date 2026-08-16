# `stock_observations` テーブル

## 目的

個体Stockを観察した時点の草丈、メモ、画像を時系列で記録するテーブルです。
現在値の更新だけでは失われる観察内容を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 株観察記録ID |
| `stock_id` | `bigint` | 不可 | なし | FK | 観察対象の株ID |
| `height_cm` | `decimal(10,2)` | 可 | `NULL` | なし | 観察時点の草丈（cm） |
| `memo` | `text` | 可 | `NULL` | なし | 観察内容の補足 |
| `recorded_at` | `datetime` | 不可 | なし | なし | 観察日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `stock_id`
- `stock_id`、`recorded_at`は必須とする
- `height_cm`を入力する場合は0以上とする

## 関連

- `StockObservation belongs_to Stock`
- `StockObservation has_one_attached Image`
- `stocks.id`を`stock_id`で参照する

## 業務ルール

- 観察した日時は`created_at`ではなく`recorded_at`に記録する
- 草丈、メモ、画像の少なくとも1つを必須とする
- 草丈を測定していない観察では`height_cm`を空にできる
- Stockの現在の草丈は、草丈が入力された最新のStockObservationから取得する
- 工程変更や場所移動はStockの通常更新として扱い、このテーブルには記録しない
