# データZIPエクスポート

管理画面の「データを出力」から、現在の業務データと添付画像を1つのZIPとして
ダウンロードできる。レコードは通常のCSV、画像は独立したバイナリファイルとして
格納する。

## 出力対象

- Location
- Plant
- Stock

上記3モデルを主レコードとして出力する。ログ系レコードは、対応する主レコードの
直後へ次の関連単位で出力する。

- `Location`の`location_observations`（LocationObservation）
- `Stock`の`stock_action_logs`（StockActionLog）
- `Stock`の`stock_observations`（StockObservation）

Active Storageの内部テーブルは出力しない。画像を持つPlant、Location、Stock、
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
            ├── <filename>
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

`attributes_json`は出力時点の全カラムを含む。Plantの学名、生育条件、
水やり、肥料、風通しなどの育成ガイド、Stockの数量・メモ・ラベル、
StockActionLogの移動元・移動先、変更前後の状態・数量もこのJSON内へ出力される。

主レコード行では`main_record_type`と`main_record_id`が自身を指す。ログ系レコードは
同じ2列で対応するLocationまたはStockを指すため、`attributes_json`を解析しなくても
主レコードとのまとまりを判別できる。各主レコードとそのログはID順に出力する。

## 生成方法

ZIPは一時ファイルへ完成させてからレスポンスへチャンク転送する。アーカイブ全体や
画像全体をメモリへ保持しない。画像はActive Storageからチャンク単位で読み出して
ZIPへ書き込む。

CSV生成時はRubyのCSVライブラリへ各行を渡し、Base64や引用符を手作業で連結しない。
このため画像サイズはCSVの構文へ影響せず、`data.csv`は通常のCSVとして最後まで
解析できる。
