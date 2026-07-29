# `locations` テーブル

## 目的

株を保管または栽培する場所を管理するマスターテーブルです。
株の現在地と、場所単位で取得する気象・環境観察記録の参照先になります。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 場所ID |
| `code` | `string` | 不可 | なし | UK | 場所を一意に識別するコード |
| `prefix` | `string` | 不可 | なし | UK | 場所を一意に識別するプレフィックス |
| `name` | `string` | 不可 | なし | UK | 表示用の場所名 |
| `environment` | `string` | 不可 | `indoor` | なし | 屋内・屋外の区分 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `code`、`prefix`、`name`
- `code`、`prefix`、`name`、`environment`は必須とする

## 関連

- `Location has_one_attached Image`
- `Location has_many Stocks`
- `Location has_many LocationObservations`
- `Location has_many OutgoingStockActionLogs`
- `Location has_many IncomingStockActionLogs`
- `stocks.location_id`、`location_observations.location_id`、
  `stock_action_logs.from_location_id`、`stock_action_logs.to_location_id`から参照される
- Stock、LocationObservation、または移動履歴が存在するLocationは削除できない

## 業務ルール

- 同じ`code`を持つ場所は重複登録できない
- 同じ`prefix`または`name`を持つ場所は重複登録できない
- 株ごとの現在地は`stocks.location_id`で管理する
- 場所単位の気象・環境情報は`location_observations`に記録する
- 最新の場所観察記録は`recorded_at`で判定し、未設定の場合は`created_at`を使用する
- `environment`は`indoor`または`outdoor`とする
- `environment`と複数のLocationは、アクション一括記録画面で育成中のStockを
  絞り込む条件として使用する
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
