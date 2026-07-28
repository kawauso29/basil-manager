# `bulk-action-filter` Controller

## 目的

アクション一括記録画面で、屋内・屋外とロケーションの条件に一致する
育成中の株だけを表示し、選択件数を管理します。

## Viewとの接続

- Controller: `data-controller="bulk-action-filter"`
- 環境ラジオボタン: `environment` target
- ロケーションの行: `locationRow` target
- ロケーションのチェックボックス: `locationCheckbox` target
- 株の行: `stockRow` target
- 株のチェックボックス: `stockCheckbox` target
- 選択件数: `selectionCount` target
- 送信ボタン: `submit` target
- 該当株なしの表示: `emptyState` target

## 処理

- 環境を変更すると、その環境に属するロケーションだけを選択可能にする
- ロケーションは複数選択でき、未選択の場合は選んだ環境の全ロケーションを対象にする
- 環境またはロケーションを変更すると、選択したいずれかの条件に一致する株だけを表示する
- 非表示の株のチェックボックスは無効化し、送信対象に含めない
- 全選択・全解除は、現在表示している株だけを対象にする
- 選択件数を表示し、0件の場合は送信ボタンを無効化する

絞り込みは操作性のためのクライアント側処理です。サーバー側では、
送信された株がすべて指定した環境・ロケーションにある育成中の株であり、
作業種別が一括記録可能であることを改めて検証します。
