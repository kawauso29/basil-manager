# 起動
docker-compose up -d

# url
http://localhost:3000/

# shell
docker-compose exec web bash

# db
host: localhost
library: libpq-15.dll
name: postgres
pass: password
port: 5042

# Active Storageの永続化

## 保存先

production環境では、Active Storageの`:local`サービスを使用する。

`config/storage.yml`の`local`サービスは、ファイルを
`Rails.root.join("storage")`へ保存する。
本番コンテナの`Rails.root`は`/rails`のため、実際の保存先は次になる。

```text
/rails/storage
```

Active Storageの管理情報はPostgreSQLへ保存されるが、画像ファイル本体は
`/rails/storage`へ保存される。

## Northflank

Northflankへデプロイする場合は、サービスにPersistent Volumeを追加する。
Volumeがない場合、コンテナの再作成や再デプロイによって画像ファイルが
失われる。

Volumeは次の内容で作成する。

- 名称: `basil-manager-storage`
- ストレージタイプ: `NVMe`
- サイズ: 利用可能な最小サイズから開始する
- コンテナマウント経路: `/rails/storage`
- カスタムボリュームマウントパス: 使用しない

単一インスタンスで運用する場合は、Single Read/WriteのVolumeを使用する。

`config/deploy.yml`にもKamal用のVolume設定があるが、この設定は
Northflankには適用されない。Northflankの管理画面からVolumeを作成して
サービスへ接続する。

## 接続確認

Volumeを追加するとサービスが再起動する。
再起動後にNorthflankのShellから次を実行する。

```bash
mountpoint /rails/storage
test -w /rails/storage && echo writable || echo not-writable
df -h /rails/storage
```

`mountpoint`が成功し、`writable`と表示されることを確認する。

## バックアップ

Plantと画像の関連情報はPostgreSQL、画像ファイル本体はPersistent Volumeに
保存される。復旧できるように、PostgreSQLと`/rails/storage`の両方を
バックアップ対象にする。
