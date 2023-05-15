# XRAY VLESS

The script demand the following tools

- `docker`
- `docker-compose`
- `jq`

```bash
bash run.sh clean; rm -f .options

bash run.sh clean
bash run.sh clean; rm -f server/docker-compose.yaml server/config.json; bash run.sh -v -m server -p shadowsocks start

env SERVER=8.8.8.8 bash run.sh -v -m server -p shadowsocks -s kcp start

bash run.sh -v -m client -p shadowsocks -s kcp start

# vmess
bash run.sh clean; rm -f server/docker-compose.yaml server/config.json; bash run.sh -v -m server -p vmess start

bash run.sh clean; rm -f client/docker-compose.yaml client/config.json; bash run.sh -v -m client -p vmess start

bash run.sh clean; rm -f server/docker-compose.yaml server/config.json; bash run.sh -v -m server -p vmess -s kcp start

bash run.sh clean; rm -f client/docker-compose.yaml client/config.json; bash run.sh -v -m client -p vmess -s kcp start
```

## Reference

- <https://github.com/XTLS/Xray-examples>
