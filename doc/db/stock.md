# `stocks` テーブル

## 目的

同じ条件でまとめて扱う株の管理単位を管理するテーブルです。
1件のStockは1株に限らず、同じ場所、状態、栽培方法で管理する複数株を
まとめて表せます。植物の種類、現在の保管場所、状態、栽培方法、増殖元、
管理単位内の数量を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 株ID |
| `plant_id` | `bigint` | 不可 | なし | FK | 植物ID |
| `location_id` | `bigint` | 不可 | なし | FK | 現在の保管場所ID |
| `parent_stock_id` | `bigint` | 可 | `NULL` | FK | 増殖元となった株ID |
| `parent_stock_candidate` | `boolean` | 不可 | `false` | なし | 新しい株の親株として選択可能か |
| `public_token` | `string` | 不可 | なし | UK | 公開画面で株を識別するトークン |
| `code` | `string` | 不可 | なし | UK | 株の管理コード |
| `status` | `string` | 不可 | なし | なし | 現在の管理状態 |
| `growing_method` | `string` | 不可 | なし | なし | 栽培方法 |
| `propagation_method` | `string` | 可 | `NULL` | なし | 増殖方法 |
| `quantity` | `integer` | 不可 | `1` | なし | 管理単位に含まれる株数 |
| `memo` | `text` | 可 | `NULL` | なし | 管理単位の現在の補足 |
| `completion_reason` | `string` | 可 | `NULL` | なし | 育成完了理由 |
| `completed_at` | `datetime` | 可 | `NULL` | なし | 育成完了日時 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `public_token`、`code`
- インデックス: `plant_id`、`location_id`、`parent_stock_id`
- `plant_id`、`location_id`、`code`、`public_token`、`status`、
  `growing_method`、`quantity`は必須とする
- `quantity`は1以上の整数とする
- `parent_stock_id`には自身の`id`を指定できない
- 親株と子株の`plant_id`は同一とする
- 新しく`parent_stock_id`へ指定するStockは`parent_stock_candidate = true`とする

## 関連

- `Stock belongs_to Plant`
- `Stock belongs_to Location`
- `Stock belongs_to ParentStock`（任意）
- `Stock has_many ChildStocks`
- `Stock has_many StockActionLogs`
- `Stock has_many StockObservations`
- 子株が存在するStockは削除できない
- Stockを削除した場合は、関連するStockActionLogとStockObservationも削除する

## 業務ルール

- 各管理単位は、植物の種類と現在の保管場所を1件ずつ持つ
- 同じ場所、状態、栽培方法でまとめて扱う複数株は、1件のStockと
  `quantity`で管理する
- 管理条件が分かれた場合だけStockを分ける
- `memo`には管理単位の現在の補足を記録する。作業時点の履歴は
  `stock_action_logs.memo`へ記録する
- 増殖元がある場合は`parent_stock_id`で生物学的な元の株を参照する
- `parent_stock_candidate`は新しい子株の親として選択できるかを表す。
  実際に子株を持つかどうかとは別に管理する
- 親株の選択肢には、同じ植物に属する育成中の
  `parent_stock_candidate = true`のStockだけを表示する
- 既存の親子関係は親株候補フラグを外した後も保持する
- 管理上の分割では分割元を親株にせず、新しいStockにも分割前と同じ
  `parent_stock_id`を設定する
- `quantity`は通常編集では変更せず、専用の数量変更操作を使用する
- 場所、状態、数量の変更は専用操作を使用し、変更前後の値を
  `stock_action_logs`へ構造化して記録する
- 外部公開時は連番の`id`ではなく`public_token`を使用する
- 状態の履歴は`stock_action_logs`、観察値は`stock_observations`に記録する
- `status`は`starting`、`rooting`、`growing`のいずれかとする
- `growing_method`は`pot`、`planter`、`flowerpot`、`water`、`other`のいずれかとする
- `propagation_method`は未設定、`cutting_soil`、`cutting_water`、`seed`のいずれかとする
- `completion_reason`は未設定、`cultivation_ended`、`harvested`、`discarded`のいずれかとする
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う

## Lotとの関係

- 現在のStockは、同じ条件でまとめて扱う管理単位であり、運用上のLotに近い
- `quantity`はLotそのものではなく、その管理単位に含まれる株数である
- 購入日や仕入先などの由来情報を複数Stockで共有したい場合や、管理単位を
  またいだトレーサビリティが必要になった場合に、独立したLotモデルを検討する
- 現段階では独立したLotモデルや管理分割専用モデルは設けない
