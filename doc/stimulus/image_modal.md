# Image Modal Controller

サムネイルをクリックしたときに、画像をモーダル内で拡大表示する。

- Controller: `app/javascript/controllers/image_modal_controller.js`
- Layout: `app/views/layouts/admin.html.erb`
- Helper: `expandable_thumbnail`（`app/helpers/application_helper.rb`）

## Viewとの接続

管理画面の`body`に`data-controller="image-modal"`を設定する。レイアウト内の`dialog`と`img`をそれぞれ`dialog`、`image`ターゲットとして持つ。

`expandable_thumbnail`は、100pxのサムネイルと元画像のURLをボタンのStimulusパラメータに設定する。元画像はアップロード時に最大1000pxへ縮小済みである。クリックすると`open`が画像URLと代替テキストをモーダルへ反映し、`dialog.showModal()`で表示する。

## 操作

- サムネイルをクリック: 拡大表示
- 閉じるボタン、モーダル外のクリック、Escキー: モーダルを閉じる
- 閉じた後: `src`と`alt`を空にして、不要な画像表示を残さない
