# README

This repo help to setup a Shadowsocks with docker. The following plugin will be enabled conditionally.

- kcptun (Use this for `CN2` VPS). Improve the latency and bandwidth.
- sip003 (xray-plugin)

Android client can not support both xray-plugin and kcptun plugin.

## ShadowSocks Server

The server will always start with a kcptun service, sip003 is optional

```bash
# Clean the environment (optional)
rm -f .options

# start the service, this is prefer.
env SHADOWSOCKS_PASSWORD= SHADOWSOCKS_METHOD=aes-256-gcm SIP003_PLUGIN=xray-plugin SIP003_PLUGIN_OPTS=mode=grpc bash run.sh start server

# stop and remove the service
bash run.sh clean; bash run start server
```

## ShadowSocks Client

```bash
# Fill .option, does not forget shadowsocks_server
bash run.sh clean; bash run.sh start client
```

## KCP client

```bash
# Fill .option, does not forget shadowsocks_server
bash run.sh clean kcp; bash run.sh start kcp
```

Run `curl --proxy "http://localhost:1080" -Lv http://httpbin.org/get` to test

If you met any issues, try to run the following to clean any configurations

```bash
bash run.sh clean
```

## `.options` Examples

Setup server at first, then copy `.options` to client side, add `shadowsocks_server`

```text
kcptun_port=23399
kcptun_version=v20240107
shadowsocks_password=
shadowsocks_port=22314
shadowsocks_rust_version=v1.18.2
#shadowsocks_server=
#sip003_plugin_opts=mode=grpc
#sip003_plugin=xray-plugin
v2ray_plugin_version=v1.3.2
xray_plugin_version=v1.8.9
```

## Reference

- <https://github.com/teddysun/xray-plugin>
- <https://github.com/shadowsocks/v2ray-plugin>

The kcp options are <https://hub.docker.com/r/horjulf/kcptun> or <https://hub.docker.com/r/playn/kcptun>.
But use this image from this repo.
