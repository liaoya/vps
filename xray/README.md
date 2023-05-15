# XRAY VLESS

The script demand the following tools

- `docker`
- `docker-compose`
- `jq`

```bash
rm -f .options
export SERVER=

# vless
bash run.sh -m server -p shadowsocks create

bash run.sh -m client -p shadowsocks create

bash run.sh -m server -p shadowsocks -s kcp create

bash run.sh -m client -p shadowsocks -s kcp create

# vless
bash run.sh -m server -p vless create

bash run.sh -m client -p vless create

bash run.sh -m server -p vless -s kcp create

bash run.sh -m client -p vless -s kcp create

# vmess
bash run.sh -m server -p vmess create

bash run.sh -m client -p vmess create

bash run.sh -m server -p vmess -s kcp create

bash run.sh -m client -p vmess -s kcp create
```

## Reference

- <https://github.com/XTLS/Xray-examples>
