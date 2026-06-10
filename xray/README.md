# XRAY Configuration

The script demand the following tools

- `docker`
- `docker compose` plugin
- `jq`
- `yq`

TODO

- change network for shadowsocks
- remove kcp seed for shadowsocks

## Create Server

Create configuration, `create.sh` will create a directory e.g. `vless-xhttp-server` and file `.vless-xhttp.env` (to create client)

```bash
export VLESS_ID=$(cat /proc/sys/kernel/random/uuid)

# vless + xhttp,
./create.sh -m server -p vless -s xhttp

# vless + mkcp
KCP_SEED= ./create.sh -m server -p vless -s kcp

# shadowsocks + xhttp
SHADOWSOCKS_METHOD=aes-128-gcm SHADOWSOCKS_PASSWORD= ./create.sh -m server -p shadowsocks -s xhttp

# shadowsocks + mkcp
SHADOWSOCKS_METHOD=aes-256-gcm SHADOWSOCKS_PASSWORD= ./create.sh -m server -p shadowsocks -s kcp

# use option file
./create.sh -f .vless-xhttp.env
```

## Run Server

In the directory, e.g. `vless-xhttp-server`, run

```sh
./run.sh start
```

## Create Client

The following command will create a directory e.g. `vless-xhttp-client`

```sh
./create.sh -m client -f .vless-xhttp.env
```

## Run Client

In the directory, e.g. `vless-xhttp-client`, run

```sh
./run.sh start
```

## All in One

- Run `./create-all-in-one-server.sh` to create the server with the existing `.env` file
- Run the following to create the new server

```sh
rm -fr .*.env *-server *-client

export KCP_SEED=${KCP_SEED:-"$(tr -cd '[:alnum:]' </dev/urandom | fold -w10 | head -n1)"}
export PREFIX=${PREFIX:-$(hostname)}
export SHADOWSOCKS_METHOD=${SHADOWSOCKS_METHOD:-aes-128-gcm}
export SHADOWSOCKS_PASSWORD=${SHADOWSOCKS_PASSWORD:-"$(tr -cd '[:alnum:]' </dev/urandom | fold -w10 | head -n1)"}
export VLESS_ID=${VLESS_ID:-$(cat /proc/sys/kernel/random/uuid)}

./create-all-in-one-server.sh
```

## Reference

- <https://github.com/XTLS/Xray-examples>
- <https://github.com/chika0801/Xray-examples>

- <https://www.chonglangbiji.com/security/xray-allowinsecure-deprecation/>
- [Xray-core新特性使用教程（固定服务器证书、更改XHTTP填充查询参数名称、路由规则缓存）](https://echonet.icu/t/topic/189)
- <https://github.com/2dust/v2rayN/discussions/9460>

`xray tls hash --cert xray.crt` or `openssl x509 -in xray.crt -noout -fingerprint -sha256 | awk -F= '{print $2}' | tr -d ':' | tr 'A-Z' 'a-z'`
