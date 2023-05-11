# V2Rary VMESS

The script demand the following tools

- `docker`
- `docker-compose`
- `jq`

## Server

Run `bash run.sh start server` to start a new or existing docker. It will create a `.options` file (Some values are removed).

```
mkcp_client_down_capacity=200
mkcp_client_up_capacity=50
mkcp_header_type=dtls
mkcp_port=28413
mkcp_seed=
mkcp_server_down_capacity=200
mkcp_server_up_capacity=200
mkcp_uuid=34cc8236-1092-4e7a-94eb-cc15a254862b
mux_concurrency=4
port=27212
server=
uuid=f5ca642a-8ab2-46ac-8c58-a5b5bd000688
v2ray_version=v5.4.1
```

The server will start

- TCP Vmess server
- A UDP Vmess KCP server

Run `bash run.sh clean; bash run.sh start server` if you change the value in `.options`

## Client

Copy `.options` on VPS to local, run `bash run.sh start client` to start local vmess proxy. Use the following to testing.

```bash
curl --proxy http://localhost:1080 -Lv http://httpbin.org/get

curl --proxy http://localhost:1090 -Lv http://httpbin.org/get
```

Change `.options` and run

```bash
./run.sh clean; ./run.sh start client

./run.sh clean; ./run.sh start server
env MKCP_SEED= ./run.sh start server
```

Consider `teddysun/v2ray` since it update more often.

The openwrt luci app ShadowSock does not support mkcp `seed`, PassWall does not allow `seed` empty.

- Never use [mux](https://www.v2ray.com/chapter_02/mux.html)
- Always use v2ray for vmess protocol, never xray.
