# XRAY VLESS

The script demand the following tools

- `docker`
- `docker-compose`
- `jq`

```bash
bash run.sh clean; rm -f .options

bash run.sh clean
env SERVER=8.8.8.8 bash run.sh -v -m server -p shadowsocks start

env SERVER=8.8.8.8 bash run.sh -v -m server -p shadowsocks -s kcp start

bash run.sh -v -m client -p shadowsocks -s kcp start
```

## Reference

- <https://github.com/XTLS/Xray-examples>
