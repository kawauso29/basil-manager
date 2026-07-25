# `plants` テーブル

## 目的

管理対象となる植物の種類を保持するマスターテーブルです。
個別の株や栽培単位は`stocks`テーブルで管理し、`plants`にはそれらに
共通する植物名と識別コードを保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 植物ID |
| `code` | `string` | 不可 | なし | UK | 植物を一意に識別するコード |
| `prefix` | `string` | 不可 | なし | UK | 株コードに使用するプレフィックス |
| `name` | `string` | 不可 | なし | UK | 表示用の植物名 |
| `last_stock_number` | `integer` | 可 | `0` | なし | 最後に発行した株番号 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `code`、`prefix`、`name`
- `code`、`prefix`、`name`は必須とする

## 関連

- `Plant has_one_attached Image`
- `Plant has_many Stocks`
- `stocks.plant_id`から参照される
- Stockが存在するPlantは削除できない

## 業務ルール

- 同じ`code`を持つ植物は重複登録できない
- 同じ`prefix`または`name`を持つ植物は重複登録できない
- 個別の株の状態、栽培方法、増殖方法は`plants`ではなく`stocks`で管理する
- `last_stock_number`は株コードの採番に使用し、通常の編集画面では変更しない
