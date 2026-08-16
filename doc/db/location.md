# `locations` テーブル

## 目的

苗群または個体株を保管・育成する場所を管理するマスターテーブルです。
NurseryGroupとStockがそれぞれの現在地として参照します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 場所ID |
| `code` | `string` | 不可 | なし | UK | 場所を一意に識別するコード |
| `name` | `string` | 不可 | なし | UK | 表示用の場所名 |
| `environment` | `string` | 不可 | `indoor` | なし | 屋内・屋外の区分 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `code`、`name`
- `code`、`name`、`environment`は必須とする

## 関連

- `Location has_one_attached Image`
- `Location has_many NurseryGroups`
- `Location has_many Stocks`
- NurseryGroupまたはStockから参照されているLocationは削除できない

## 業務ルール

- 同じ`code`または`name`を持つ場所は重複登録できない
- 鉢上げ前の苗群の現在地は`nursery_groups.location_id`で管理する
- 個体株の現在地は`stocks.location_id`で管理する
- `environment`は`indoor`または`outdoor`とする
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
