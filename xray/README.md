# XRAY VLESS

The script demand the following tools

- `docker`
- `docker-compose`
- `jq`

```bash
bash run.sh clean; rm -f .options

export SERVER=

# vless
bash run.sh clean; bash run.sh -v -m server -p shadowsocks start

bash run.sh clean; bash run.sh -v -m client -p shadowsocks start

bash run.sh clean; bash run.sh -v -m server -p shadowsocks -s kcp start

bash run.sh clean; bash run.sh -v -m client -p shadowsocks -s kcp start

# vless
bash run.sh clean; bash run.sh -v -m server -p vless start

bash run.sh clean; bash run.sh -v -m client -p vless start

bash run.sh clean; bash run.sh -v -m server -p vless -s kcp start

bash run.sh clean; bash run.sh -v -m client -p vless -s kcp start

# vmess
bash run.sh clean; bash run.sh -v -m server -p vmess start

bash run.sh clean; bash run.sh -v -m client -p vmess start

bash run.sh clean; bash run.sh -v -m server -p vmess -s kcp start

bash run.sh clean; bash run.sh -v -m client -p vmess -s kcp start
```

## Reference

- <https://github.com/XTLS/Xray-examples>
