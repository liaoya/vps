# XRAY VLESS

The script demand the following tools

- `docker`
- `docker-compose`
- `jq`

```bash
rm -f .options
export SERVER=

# shadowsocks
# Initial the options files
bash create.sh -m server -p shadowsocks
bash create.sh -m server -p shadowsocks -s kcp

bash create.sh -m server -f .raksmart.shadowsocks.options
bash create.sh -m client -f .raksmart.shadowsocks.options

# vless
# Initial the options files
rm -f .options
bash create.sh -m server -p vless
rm -f .options
env KCP_SEED= bash create.sh -m server -p vless -s kcp
rm -fr .options
env QUIC_KEY= bash create.sh -m server -p vless -s quic

# vmess
bash create.sh -m server -p vmess
bash create.sh -m server -p vmess -s kcp

```

## Reference

- <https://github.com/XTLS/Xray-examples>
