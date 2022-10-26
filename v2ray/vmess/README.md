# V2Rary Server

The server both support tcp and mkcp protocol, the server support both tcp and mkcp.

The openwrt luci app ShadowSock does not support mkcp `seed`, PassWall does not allow `seed` empty. Consider `teddysun/v2ray` since it update more often.

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

- Never use [mux](https://www.v2ray.com/chapter_02/mux.html)
- Always use v2ray for vmess protocol, never xray.
