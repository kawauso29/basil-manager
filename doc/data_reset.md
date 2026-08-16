# 全業務データ初期化

`db/data/20260815_reset_all_business_data.rb`は、生産管理schemaへの切替時に一度だけ
実行するデータ削除スクリプトである。運用データとActive Storageへ保存した画像を
すべて削除する。

このスクリプトはバックアップを作成しない。ZIPエクスポートはAIへ本番データを
提供するための機能であり、復元用バックアップではない。必要なバックアップは
別の方法で用意する。誤実行を避けるため、固定の確認文字列が一致した場合だけ削除する。

## 対象

- Plant
- Location
- ProductionLot
- NurseryGroup
- Stock
- StockObservation
- 旧schemaに`stock_action_logs`が残っている場合のStockActionLog
- Active StorageのAttachment、VariantRecord、Blob、およびBlobに対応する画像実体

Solid Queue、Solid Cache、Solid Cableなど、業務データではない内部テーブルは対象外とする。
主キーのシーケンスはリセットしない。

## 実行前の件数確認

確認文字列を指定せずに実行すると、対象テーブルごとの件数を表示してから中止する。

```bash
docker compose exec web \
  bin/rails runner "load 'db/data/20260815_reset_all_business_data.rb'"
```

新旧どちらかのschemaにしか存在しないテーブルは、存在しない環境では0件と表示する。

## 実行

developmentなどproduction以外では、次の固定文字列を指定する。

```bash
docker compose exec \
  -e CONFIRM=DELETE_ALL_BASIL_MANAGER_DATA \
  web bin/rails runner "load 'db/data/20260815_reset_all_business_data.rb'"
```

productionでは、環境を明示したうえで二つ目の固定文字列も指定する。

```bash
docker compose exec \
  -e RAILS_ENV=production \
  -e CONFIRM=DELETE_ALL_BASIL_MANAGER_DATA \
  -e ALLOW_PRODUCTION_RESET=DELETE_ALL_BASIL_MANAGER_PRODUCTION_DATA \
  web bin/rails runner "load 'db/data/20260815_reset_all_business_data.rb'"
```

新しい生産管理schemaのmigrationより前に、アプリケーションから同時に新規登録されない
メンテナンス時間中に実行する。削除完了後にmigrationを実行する。

## 削除順と再実行

ProductionLotの`source_stock_id`をNULLへ戻して循環参照を解消した後、外部キーの子から
StockObservation、旧StockActionLog、Stock、NurseryGroup、ProductionLot、Location、
Plantの順に、同一トランザクションで削除する。Active StorageのAttachmentと
VariantRecordもこのトランザクションで削除する。

DB削除のコミット後、各Blobについてストレージ上の画像実体を先に削除し、成功した
BlobだけをDBから削除する。ストレージ障害で途中停止した場合、未削除のBlob行は残る。
同じコマンドを再実行すると残った画像から処理を再開できる。
