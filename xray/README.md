# XRAY Configuration

The script demand the following tools

- `docker`
- `docker compose` plugin
- `jq`
- `yq`

TODO

- change network for shadowsocks
- remove shadowsocks password as kcp and xhttp has been encrypted already

## Create Server

Create configuration, `create.sh` will create a directory e.g. `vless-xhttp-server` and file `.vless-xhttp.options` (to create client)

```bash
export VLESS_ID=$(cat /proc/sys/kernel/random/uuid)

# vless + xhttp,
./create.sh

# vless + mkcp
./create.sh -s kcp

KCP_SEED= ./create.sh -s kcp

# shadowsocks + xhttp
./create.sh -p shadowsocks

SHADOWSOCKS_METHOD=aes-128-gcm SHADOWSOCKS_PASSWORD= ./create.sh -p shadowsocks

# shadowsocks + mkcp
./create.sh -p shadowsocks -s kcp

KCP_SEED= SHADOWSOCKS_METHOD=aes-128-gcm SHADOWSOCKS_PASSWORD= VLESS_ID= ./create.sh -p shadowsocks -s kcp

# use option file
./create.sh -f .vless-xhttp.options

ENV PREFIX=$(hostname) ./create.sh
```

## Run Server

In the directory, e.g. `vless-xhttp-server`, run

```sh
./run.sh start
```

## Create Client

The following command will create a directory e.g. `vless-xhttp-client`

```sh
./create.sh -m client -f .vless-xhttp.options
```

## Run Server

In the directory, e.g. `vless-xhttp-client`, run

```sh
./run.sh start
```

## All in One

- Run `./create-all-in-one-server.sh` to create the server with the existing `.options` file
- Run the following to create the new server

```sh
rm -fr .*.options *-server *-client

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
