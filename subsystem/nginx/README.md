# Nginx のビルド

元の自前ビルドと同じ機能・バージョンを維持しています。

- Nginx 1.15.8（通常版と `nginx-debug`）
- OpenResty LuaJIT 2.1-20190131、ngx_devel_kit 0.3.1rc1、lua-nginx-module 0.10.14rc5、lua-cjson 2.1.0.7
- PCRE 8.39
- HTTP SSL / HTTP/2、realip、addition、sub、DAV、FLV、MP4、gunzip、gzip_static、random_index、secure_link、stub_status、auth_request、slice
- stream、stream SSL / ssl_preread / realip、mail / mail SSL、threads、file AIO、compat
- XSLT、image_filter、HTTP GeoIP、stream GeoIP の動的モジュール（通常版・デバッグ版）
- `envsubst`、タイムゾーンデータ、標準出力・標準エラーへのログ転送

OSDN 経由の PCRE ダウンロードを [Exim の PCRE アーカイブ](https://ftp.exim.org/pub/pcre/)に変更しました。
Nginx の署名鍵は[署名者の配布先](https://freenginx.org/keys/mdounin.key)から HTTPS で取得し、元のフィンガープリント
`B0F4253373F8F6F510D42178520A9993A1C052F8` と照合してからソースの署名を検証します。
キーサーバーへの接続は不要です。`set -eux` により途中の失敗で停止し、失敗箇所をログに残します。

リポジトリのルートから実行します。

```sh
docker compose -f toolkit/swarm/production/infra/docker-compose.yml build --pull eastjcojp
docker run --rm --network none -i --entrypoint sh \
  ghcr.io/ej-aoat/ejtech/ejtech-nginx:latest -s < subsystem/nginx/tests/smoke.sh
docker run --rm --network none \
  --mount type=bind,src="$PWD/app/www/nginx.conf",dst=/etc/nginx/nginx.conf,readonly \
  ghcr.io/ej-aoat/ejtech/ejtech-nginx:latest nginx -t
```

スモークテストは通常版・デバッグ版それぞれで全動的モジュールを読み込み、LuaJIT / FFI / cjson / PCRE を使う HTTP 応答を確認します。
設定と公開ファイルは従来どおり Compose のボリュームで配置します。
