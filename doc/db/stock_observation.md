# `stock_observations` テーブル

## 目的

株を観察した時点の測定値とメモを時系列で記録するテーブルです。
株の成長過程を、作業履歴とは分けて保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 株観察記録ID |
| `stock_id` | `bigint` | 不可 | なし | FK | 観察対象の株ID |
| `height_cm` | `decimal(10,2)` | 可 | `NULL` | なし | 観察時点の高さ（cm） |
| `memo` | `text` | 可 | `NULL` | なし | 観察内容の補足 |
| `recorded_at` | `datetime` | 可 | `NULL` | なし | 観察日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `stock_id`
- `stock_id`は必須とする

## 関連

- `StockObservation belongs_to Stock`
- `StockObservation has_one_attached Image`
- `stocks.id`を`stock_id`で参照する

## 業務ルール

- 観察した日時は`created_at`ではなく`recorded_at`に記録する
- 日時が未確定の場合は`recorded_at`を空にして作成し、後から入力できる
- 高さを測定していない観察では`height_cm`を空にできる
- 測定値以外の状態は`memo`に記録する
