# README

This repo contains

- ansible scripts
- docker image
- shadowsocks deployment scripts

Enable ufw on Ubuntu server and open the port for Shadowsocks

```bash
# Open a port
sudo ufw allow 8388

# Show the status
sudo ufw status numbered

# delete a rule
sudo ufw delete 4
```

```bash
# https://www.baeldung.com/linux/udp-port-testing
nc -vz -u 155.94.149.79 24222
```

```bash
cat ~/Documents/vps/ss-rust/.options

cat ~/Documents/vps/v2ray/vmess/.options
```

- <https://really-simple-ssl.com/mozilla_pkix_error_required_tls_feature_missing/>： `MOZILLA_PKIX_ERROR_REQUIRED_TLS_FEATURE_MISSING`

```bash
# curl -sL "https://api.github.com/repos/xtaci/kcptun/tags" | jq -r '.[0].name'
# curl -sL "https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest" | jq -r '.[0].name'
# curl -sL "https://api.github.com/repos/teddysun/xray-plugin/tags" | jq -r '.[0].name'
# curl -sL https://api.github.com/repos/xtls/xray-core/releases/latest | jq -r .tag_name

export KCPTUN_VERSION=v20241119
export SHADOWSOCKS_RUST_VERSION=v1.21.2
export XRAY_PLUGIN_VERSION=v1.8.24
export XRAY_VERSION=v1.8.24
```
