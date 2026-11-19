#!/bin/sh
# Run inside the built image: docker run --rm --network none -i --entrypoint sh \
#   ghcr.io/ej-aoat/ejtech/ejtech-nginx:latest -s < subsystem/nginx/tests/smoke.sh
set -eu

for binary in nginx nginx-debug; do
    suffix=
    if [ "$binary" = nginx-debug ]; then suffix=-debug; fi
    cat > /tmp/nginx-smoke.conf <<EOF
load_module /usr/lib/nginx/modules/ngx_http_xslt_filter_module${suffix}.so;
load_module /usr/lib/nginx/modules/ngx_http_image_filter_module${suffix}.so;
load_module /usr/lib/nginx/modules/ngx_http_geoip_module${suffix}.so;
load_module /usr/lib/nginx/modules/ngx_stream_geoip_module${suffix}.so;
user nginx;
pid /tmp/nginx-smoke.pid;
error_log /dev/stderr;
events {}
http {
    access_log off;
    server {
        listen 127.0.0.1:18080;
        location / {
            content_by_lua_block {
                local cjson = require "cjson"
                local ffi = require "ffi"
                assert(jit.version_num >= 20100)
                assert(ffi.sizeof("int") > 0)
                assert(ngx.re.find("lua123", [[\d+]]) == 4)
                ngx.say(cjson.encode({ok = true}))
            }
        }
    }
}
stream {}
mail {}
EOF
    "$binary" -t -c /tmp/nginx-smoke.conf
    "$binary" -c /tmp/nginx-smoke.conf -g 'daemon off;' &
    server_pid=$!
    trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT
    attempt=0
    response=
    until response=$(wget -q -O - http://127.0.0.1:18080/); do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 20 ]; then exit 1; fi
        sleep 0.1
    done
    test "$response" = '{"ok":true}'
    kill "$server_pid"
    wait "$server_pid"
    trap - EXIT
    echo "$binary: dynamic modules, LuaJIT, FFI, lua-cjson and PCRE passed"
done

command -v envsubst
test -f /usr/share/zoneinfo/Asia/Tokyo
