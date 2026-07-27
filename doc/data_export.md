# データCSVエクスポート

管理画面の「CSVを出力」から、現在の業務データを1つのCSVとしてダウンロードできる。CSVと画像はリクエスト中にメモリへ全件保持せず、順に書き出す。

## 出力対象

- Plant
- Location
- Stock
- StockActionLog
- StockObservation
- LocationObservation

Active Storageの内部テーブルは出力しない。画像はレコードに対応する行の`image_*`列へ含めるため、画像だけが別データになることはない。

## CSVの形式

| 列 | 内容 |
| --- | --- |
| `record_type` | モデル名 |
| `record_id` | レコードID |
| `attributes_json` | そのレコードの全カラム値を含むJSON |
| `image_filename` | 添付画像のファイル名。画像なしの場合は空 |
| `image_content_type` | 添付画像のMIMEタイプ。画像なしの場合は空 |
| `image_byte_size` | 添付画像のバイト数。画像なしの場合は空 |
| `image_data_url` | `data:<MIMEタイプ>;base64,...` 形式の画像本体。画像なしの場合は空 |

`attributes_json`は出力時点の全カラムを含む。Plantの学名、生育条件、
水やり、肥料、風通しなどの育成ガイドもこのJSON内へ出力される。

画像を持つのは現在、Plant、Location、Stock、StockObservationである。CSVは画像本体をBase64化するため、元画像より大きくなる。画像理解に対応したAIへ渡す場合は、`image_data_url`列を画像入力として取り出して渡す。
