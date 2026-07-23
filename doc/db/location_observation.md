# `location_observations` テーブル

## 目的

場所ごとの気温、天候などを時系列で記録するテーブルです。
同じ場所で管理する複数の株に共通する環境情報を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 場所観察記録ID |
| `location_id` | `bigint` | 不可 | なし | FK | 観察対象の場所ID |
| `temperature` | `decimal(4,2)` | 可 | `NULL` | なし | 観察時点の気温（℃） |
| `weather` | `string` | 可 | `NULL` | なし | 観察時点の天候 |
| `memo` | `text` | 可 | `NULL` | なし | 観察内容の補足 |
| `recorded_at` | `datetime` | 可 | `NULL` | なし | 観察日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- インデックス: `location_id`
- `location_id`は必須とする

## 関連

- `LocationObservation belongs_to Location`
- `locations.id`を`location_id`で参照する

## 業務ルール

- 観察した日時は`created_at`ではなく`recorded_at`に記録する
- 測定していない項目は空にできる
- `weather`は未設定、`sunny`、`cloudy`、`rainy`、`snowy`のいずれかとする
- 数値で表せない環境情報は`weather`または`memo`に記録する
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
