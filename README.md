# my-nicolive-history

自分が放送したニコニコ生放送の情報一覧を取得するツールです。

## 使い方

ニコニコ動画登録のメールアドレスとパスワードを入力してください。標準出力にJSON形式で情報一覧が出力されます。

```sh
ruby my_nicolive_history.rb email@example.com password
```

## その他ツール

### generage\_html.rb

ファイルに保存されたJSONを、HTMLのTABLEタグに変換します。
