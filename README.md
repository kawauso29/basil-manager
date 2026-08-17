# basil-manager

バジルなどの植物生産管理を行う、原田航希個人用のRailsアプリケーションです。種まき・挿し木から
鉢上げ、個体管理、販売可能日の設定、栽培完了までの一連の工程を、管理画面から記録・追跡します。

## 主な機能

- **Plant / Location**: 植物の品種と、株を保管・栽培する場所を管理するマスターデータ
- **ProductionLot**: 種まき・挿し木による生産の出自と開始条件を記録
- **NurseryGroup**: 鉢上げ前の数量管理。工程（発芽・間引き・発根待ちなど）を進行
- **Stock**: 鉢上げ後、または購入・譲受による直接登録の個体（1株）を管理。工程進行、
  販売可能日の設定・取消、栽培完了までを扱う
- **StockObservation**: 株の高さやメモ、写真を時系列で記録する観察ログ
- **データ出力**: 管理画面から、業務データと添付画像をまとめたZIPをダウンロード可能
  （AIへの分析・確認用途。詳細は [`doc/data_export.md`](doc/data_export.md) を参照）

各モデルの詳細な仕様は [`doc/er.md`](doc/er.md) と `doc/db/` 配下のテーブル仕様書を
参照してください。

## 技術スタック

- Ruby 3.4.10 / Rails 8.1
- PostgreSQL
- Hotwire (Turbo / Stimulus)、importmap-rails、Propshaft
- Active Storage（画像添付）
- Solid Queue / Solid Cache / Solid Cable
- Kamal（デプロイ）

## セットアップ（Docker）

本プロジェクトは開発環境としてDocker Composeを想定しています。

```bash
docker compose up
```

初回起動時に `bundle install` と `bin/rails db:prepare` が自動実行され、
`http://localhost:3000` でアプリケーションにアクセスできます。管理画面は `/admin` 配下です。

コンテナ内でコマンドを実行する場合は次のようにします。

```bash
docker compose exec web bin/rails console
```

## テスト

テストはRSpecで記述しています。

```bash
docker compose exec web bash -lc "RAILS_ENV=test bundle exec rspec"
```

特定のファイルや行だけを実行する方法など、詳細は
[`doc/rspec/README.md`](doc/rspec/README.md) を参照してください。

## Lint / 静的解析

```bash
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman
```

CI（GitHub Actions）では、RuboCopによるlint、Brakeman/bundler-audit/importmap auditに
よる脆弱性スキャン、RSpecの実行を行っています。詳細は
[`.github/workflows/ci.yml`](.github/workflows/ci.yml) を参照してください。

## ドキュメント

`doc/` ディレクトリに設計・仕様を記録しています。実装を変更する際は、関連するドキュメントも
同じ変更に含めてください（詳細は [`doc/AGENTS.md`](doc/AGENTS.md) を参照）。

- [`doc/er.md`](doc/er.md): 業務テーブル全体の関連を示すER図
- `doc/db/<table>.md`: 業務テーブルごとの詳細仕様
- [`doc/enum/README.md`](doc/enum/README.md): Rails enumとenum_helpの共通運用ルール
- [`doc/rspec/README.md`](doc/rspec/README.md): RSpecの基本とテスト種別ごとの責務
- `doc/stimulus/<controller>.md`: Stimulus Controllerの仕様
- [`doc/data_export.md`](doc/data_export.md): AI提供用データZIPエクスポートの仕様
- [`doc/data_reset.md`](doc/data_reset.md): 全業務データ初期化スクリプトの仕様
