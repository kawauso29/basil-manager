# `stocks` テーブル

## 目的

生産由来ではPlantごとに異なる、個体管理へ切り替える鉢上げを行った株を管理します。
購入・譲受した株はProductionLotとNurseryGroupを介さず直接登録できます。
1件のStockが1株を表し、現在工程、現在地、販売可能日、管理完了を保持します。

## カラム

| カラム名 | 型 | NULL | デフォルト | キー | 説明 |
| --- | --- | --- | --- | --- | --- |
| `id` | `bigint` | 不可 | なし | PK | 株ID |
| `plant_id` | `bigint` | 不可 | なし | FK | 植物ID |
| `location_id` | `bigint` | 不可 | なし | FK | 現在の保管場所ID |
| `source_nursery_group_id` | `bigint` | 可 | `NULL` | FK | 鉢上げ元の苗グループID |
| `public_token` | `string` | 不可 | なし | UK | 公開画面で株を識別するトークン |
| `stage` | `string` | 不可 | なし | なし | 現在の生産工程 |
| `stage_started_on` | `date` | 不可 | なし | なし | 現工程の開始日 |
| `potted_on` | `date` | 可 | `NULL` | なし | 個体管理へ切り替えた鉢上げ日 |
| `sale_ready_on` | `date` | 可 | `NULL` | なし | 販売可能日 |
| `completion_reason` | `string` | 可 | `NULL` | なし | 管理完了理由 |
| `completed_at` | `datetime` | 可 | `NULL` | なし | 管理完了日時 |
| `product_type` | `string` | 可 | `NULL` | なし | 公開ページで育て方を出し分ける商品形態 |
| `memo` | `text` | 可 | `NULL` | なし | 現在の補足 |
| `created_at` | `datetime` | 不可 | なし | なし | 作成日時 |
| `updated_at` | `datetime` | 不可 | なし | なし | 更新日時 |

## インデックスと制約

- 主キー: `id`
- 一意インデックス: `public_token`
- インデックス: `plant_id`、`location_id`、`source_nursery_group_id`
- `plant_id`、`location_id`、`public_token`、`stage`、`stage_started_on`は必須とする

## 関連

- `Stock belongs_to Plant`
- `Stock belongs_to Location`
- `Stock belongs_to SourceNurseryGroup`（任意）
- `Stock has_one ProductionLot through SourceNurseryGroup`
- `Stock has_many StockObservations`
- `Stock has_many SourcedProductionLots`（挿し穂を採取した親株としての関連）
- StockObservationまたは挿し穂元として参照するProductionLotがあるStockは削除できない

## 業務ルール

- 生産由来のStockは、個体管理へ切り替える鉢上げ後に作成する
- 購入・譲受した株はProductionLotとNurseryGroupなしでStockへ直接登録できる
- 1件のStockは、登録経路によらず1株を表す
- 鉢上げの基準はPlantごとに異なる。鉢サイズを設定・検証する機能はv1では持たない
- 鉢上げ元がある場合、そのNurseryGroupのProductionLotと同じPlantでなければならない
- 鉢上げ元がある場合は`potted_on`を必須とする
- 直接登録するStockでは`source_nursery_group_id`と`potted_on`を空にできる
- `stage`は`acclimating`または`growing`とする
- 工程は`acclimating`から`growing`へ進める。完了済みStockの工程は変更しない
- `sale_ready_on`は`growing`工程の稼働中Stockにだけ設定する。販売可能化を取り消す場合はNULLへ戻す
- 販売可能化は生産工程と別の現在状態として扱い、`stage`へ`sale_ready`を追加しない
- 完了時は`completion_reason`と`completed_at`を両方設定する。販売可能日を保持したまま完了できる
- `completion_reason`は`cultivation_ended`、`dead`、`transferred`のいずれかとする
- 草丈はStock本体に重複保持せず、最新のStockObservationから取得する
- 工程変更と場所移動の専用履歴は初期版では保存しない
- 外部公開時は連番の`id`ではなく`public_token`を使用する
- 購入者向けの公開ページは`/p/<public_token>`で開く。全Stockを常時公開とし、
  公開・非公開の切り替えは持たない。URLを知っている購入者だけが開けることを前提にする
- `product_type`は`hydro`または`soil`とする。空の場合、公開ページは育て方を表示しない
- enumの日本語表示と変更手順は[`enum 運用ガイド`](../enum/README.md)に従う
