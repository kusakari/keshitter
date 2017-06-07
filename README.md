# keshitter
- Twitter TLを記録するアプリです。
- 削除されたツイートだけを絞り込み表示することができます。

# Environment
- Ruby 2.4
- MySQL 5.7

## 環境変数
- あらかじめ https://dev.twitter.com/ で必要な値を取得しておいてください。

以下を環境変数に設定してください。

|キー名|値|
|:--|:--|
|CONSUMER_KEY|YOUR_CONSUMER_KEY|
|CONSUMER_SECRET|YOUR_CONSUMER_SECRET|
|ACCESS_TOKEN|YOUR_ACCESS_TOKEN|
|ACCESS_TOKEN_SECRET|YOUR_ACCESS_TOKEN_SECRET|

## config/settings.yml

|キー名|値|
|:--|:--|
|media_dir_name|メディアファイルを保存するディレクトリー名（public直下に作られます）|

# アプリ起動
- Rubyとbundlerはインストールしてある前提です。
```sh
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails server
```

## ログイン
- デフォルトでは`admin@example.com / password`でログインできますので変更してください。

# Stream Daemon
## 起動
```sh
bundle exec rails runner daemons/tweet_streaming.rb -e development
```

## 停止
- プロセスIDを調べてkillしてください。
```sh
ps -ef | grep stream
kill -QUIT <PID>
```

# 注意事項など
- **自己責任**でご利用ください。何が起こっても責任はもてません。
- 設置の質問などには回答していません。

# ライセンス
[The MIT License](https://github.com/kusakari/keshitter/blob/master/LICENSE)
