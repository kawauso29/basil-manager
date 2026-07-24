# Image Preview Controller

## 目的

Plantの編集画面で画像ファイルを選択したときに、更新ボタンを押す前に
選択中の画像を表示する。

このControllerが担当するのはブラウザ上のプレビューだけである。
画像の保存、variantの生成、ファイル形式や容量の検証は担当しない。

## 関連ファイル

- Controller: `app/javascript/controllers/image_preview_controller.js`
- 使用画面: `app/views/admin/plants/edit.html.erb`

## Controller

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]

  preview(event) {
    const file = event.target.files[0]
    if (!file) return

    this.imageTarget.src = URL.createObjectURL(file)
    this.imageTarget.hidden = false
  }
}
```

## Viewとの接続

```erb
<div data-controller="image-preview">
  <img data-image-preview-target="image" width="100" hidden><br>
  <%= f.file_field :image, data: { action: "change->image-preview#preview" } %>
</div>
```

### Controllerの指定

```html
data-controller="image-preview"
```

`image-preview`は、次のファイル名に対応する。

```text
image-preview
      ↓
image_preview_controller.js
```

`app/javascript/controllers/index.js`がcontrollersディレクトリ内の
Controllerを自動登録するため、Controllerごとのimportは不要である。

### Targetの指定

Controllerでは、操作する要素を次のように定義している。

```js
static targets = ["image"]
```

Viewでは、対象の画像要素を次のように指定する。

```html
data-image-preview-target="image"
```

これにより、Controllerから次の名前で画像要素を参照できる。

```js
this.imageTarget
```

通常のJavaScriptで`document.querySelector`を使って要素を探す部分を、
StimulusのTarget機能が担当する。

### Actionの指定

```erb
data: { action: "change->image-preview#preview" }
```

この指定は次の意味を持つ。

```text
change
  ファイル選択内容が変わったら
    ↓
image-preview
  ImagePreviewControllerの
    ↓
preview
  previewメソッドを実行する
```

## previewメソッド

### 選択されたファイルを取得する

```js
const file = event.target.files[0]
```

- `event.target`: 操作されたfile field
- `files`: 選択されたファイルの一覧
- `[0]`: 一覧の最初のファイル

Plantの画像は1枚だけ選択するため、最初のファイルを取得する。

### ファイルがなければ終了する

```js
if (!file) return
```

ファイルが取得できなかった場合は、以降の処理を行わない。
Rubyの次の書き方に近い。

```rb
return if file.nil?
```

### 一時URLを作成する

```js
URL.createObjectURL(file)
```

選択されたローカルファイルを、ブラウザ内で参照できる一時URLへ変換する。
生成されるURLは次のような形式になる。

```text
blob:http://localhost:3000/...
```

この時点では、画像はRailsやActive Storageへアップロードされていない。

### img要素へ一時URLを設定する

```js
this.imageTarget.src = URL.createObjectURL(file)
```

Targetに指定したimg要素の`src`へ一時URLを設定する。

### 非表示を解除する

```js
this.imageTarget.hidden = false
```

画像要素は、ファイル選択前には`hidden`で非表示になっている。
一時URLの設定後に`hidden`を解除して画像を表示する。

## 処理の流れ

```text
画像ファイルを選択
  ↓
changeイベントが発生
  ↓
previewメソッドを実行
  ↓
選択された最初のファイルを取得
  ↓
ブラウザ内の一時URLを作成
  ↓
img要素のsrcへ設定
  ↓
hiddenを解除
  ↓
選択中の画像を表示
```

## Active Storageとの役割分担

ImagePreviewControllerは、更新前の表示だけを担当する。

```text
ファイルを選択
  ↓
ImagePreviewController
  ブラウザ上でプレビュー
  ↓
更新ボタンを押す
  ↓
Admin::PlantsController
  Strong Parametersでimageを受け取る
  ↓
Active Storage
  元画像を保存してPlantへ関連付ける
  ↓
ActiveStorage::TransformJob
  icon_thumbとmain_thumbを生成する
```

## 現在の実装範囲

- 1枚の画像だけをプレビューする
- プレビュー幅は100pxとする
- ファイルを選択したときだけ画像を表示する
- 画像は更新ボタンを押すまで保存されない
- ファイル形式や容量はこのControllerでは検証しない

現在は最小構成を優先し、一時URLの明示的な解放処理は持たせていない。
複数画像への対応や同一画面で大量に選び直す要件が発生した場合に、
`URL.revokeObjectURL`による解放処理を追加する。
ファイル形式や容量の検証を追加する場合は、Plantモデルのvalidationで
行う。

## 動作確認

JavaScriptの構文を確認する。

```bash
node --check app/javascript/controllers/image_preview_controller.js
```

importmapへの登録を確認する。

```bash
docker compose exec web bin/importmap json | rg image_preview_controller
```

ブラウザでは次を確認する。

1. Plantの編集画面を開く
2. 画像ファイルを選択する
3. 更新ボタンを押す前に選択画像が表示される
4. 更新ボタンを押す
5. 再表示後に現在の画像として表示される
