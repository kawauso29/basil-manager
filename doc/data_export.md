# AI提供用データZIPエクスポート

本番の生産管理データをAIへ提供することを主目的として、管理画面の
「AI提供用ZIPを出力」から、現在の業務データと添付画像を1つのZIPとして
ダウンロードできる。レコードは通常のCSV、画像は独立したバイナリファイルとして
格納する。

このZIPはAIによる分析・確認の入力用であり、データベースやActive Storageを
復旧するためのバックアップではない。ZIPをアプリケーションへインポートまたは
復元する機能は提供しない。

## 出力対象

- Plant
- Location
- ProductionLot
- NurseryGroup
- Stock

上記5モデルを主レコードとして出力する。StockObservationは、対応するStockの
直後へ関連レコードとして出力する。

- `Stock`の`stock_observations`（StockObservation）

Active Storageの内部テーブルは出力しない。画像を持つPlant、Location、
StockObservationは、CSV行の`image_path`からZIP内の画像を参照できる。

## ZIPの構成

```text
basil-manager-data-YYYY-MM-DD.zip
├── data.csv
└── images
    ├── locations
    │   └── <location_id>
    │       └── <filename>
    ├── plants
    │   └── <plant_id>
    │       └── <filename>
    └── stocks
        └── <stock_id>
            └── observations
                └── <stock_observation_id>
                    └── <filename>
```

レコードIDをディレクトリへ含めるため、同名画像があっても衝突しない。
StockObservationの画像は、対応するStockの配下へ格納する。

## CSVの形式

| 列 | 内容 |
| --- | --- |
| `record_type` | モデル名 |
| `record_id` | レコードID |
| `record_role` | 主レコードは`main`、ログ系レコードは`log` |
| `main_record_type` | この行をまとめる主レコードのモデル名 |
| `main_record_id` | この行をまとめる主レコードのID |
| `association_name` | ログ系レコードを取得した関連名。主レコードの場合は空 |
| `attributes_json` | そのレコードの全カラム値を含むJSON |
| `image_filename` | 添付画像のファイル名。画像なしの場合は空 |
| `image_content_type` | 添付画像のMIMEタイプ。画像なしの場合は空 |
| `image_byte_size` | 添付画像のバイト数。画像なしの場合は空 |
| `image_path` | ZIP内の画像パス。画像なしの場合は空 |

`attributes_json`は出力時点の全カラムを含む。外部キーも含むため、AIは
ProductionLot、NurseryGroup、Stock、StockObservationの関係をCSVからたどれる。

主レコード行では`main_record_type`と`main_record_id`が自身を指す。ログ系レコードは
同じ2列で対応するStockを指すため、`attributes_json`を解析しなくても
主レコードとのまとまりを判別できる。主レコードはPlant、Location、ProductionLot、
NurseryGroup、Stockの順で出力し、各モデル内とStockObservationはID順に出力する。

## 生成方法

ZIPは一時ファイルへ完成させてからレスポンスへチャンク転送する。アーカイブ全体や
画像全体をメモリへ保持しない。画像はActive Storageからチャンク単位で読み出して
ZIPへ書き込む。

CSV生成時はRubyのCSVライブラリへ各行を渡し、Base64や引用符を手作業で連結しない。
このため画像サイズはCSVの構文へ影響せず、`data.csv`は通常のCSVとして最後まで
解析できる。
