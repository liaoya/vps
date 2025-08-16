# XRAY Configuration

The script demand the following tools

- `docker`
- `docker compose` plugin
- `jq`
- `yq`

## Create Server

Create configuration, `create.sh` will create a directory e.g. `vless-xhttp-server` and file `.vless-xhttp.options` (to create client)

```bash
export VLESS_ID=$(cat /proc/sys/kernel/random/uuid)

# vless + xhttp,
./create.sh

# vless + mkcp
./create.sh -s kcp

env KCP_SEED= ./create.sh -s kcp

# shadowsocks + xhttp
./create.sh -p shadowsocks

env SHADOWSOCKS_METHOD=aes-128-gcm SHADOWSOCKS_PASSWORD= ./create.sh -p shadowsocks

# shadowsocks + mkcp
./create.sh -p shadowsocks -s kcp

env KCP_SEED= SHADOWSOCKS_METHOD=aes-128-gcm SHADOWSOCKS_PASSWORD= ./create.sh -p shadowsocks -s kcp

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

## Reference

- <https://github.com/XTLS/Xray-examples>
- <https://github.com/chika0801/Xray-examples>
