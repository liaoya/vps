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
env KCP_SEED= XRAY_VERSION=v1.8.24 bash create.sh -m server -p vless -s kcp -f vlkcp.options
rm -fr .options
env QUIC_KEY= XRAY_VERSION=v1.8.24 bash create.sh -m server -p vless -s quic -f vlquic.options

# vmess
bash create.sh -m server -p vmess
bash create.sh -m server -p vmess -s kcp

# Use the existing option file
bash create.sh -f .vless-kcp-server.options -m server -p vless -s kcp
bash create.sh -f .vless-quic-server.options -m server -p vless -s quic
```

## Reference

- <https://github.com/XTLS/Xray-examples>
