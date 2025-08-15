# Xray + XHTTP

```sh
mkdir /etc/xray/certs
cd /etc/xray/certs

openssl req -x509 -newkey rsa:2048 -keyout xray.key -out xray.crt -days 365 -nodes -subj "/CN=yourdomain.com"
```

`server-config.json`

```json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "11111111-2222-3333-4444-555555555555",
            "level": 0
          }
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/xray/certs/xray.crt",
              "keyFile": "/etc/xray/certs/xray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
```

`client-config.json`

```json
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": { "udp": true }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "203.0.113.10",
            "port": 443,
            "users": [
              {
                "id": "11111111-2222-3333-4444-555555555555",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": true
        }
      }
    }
  ]
}
```
