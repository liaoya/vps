#!/bin/bash

if [[ ! -f "${RUNTIME}/docker-compose.yaml" ]]; then
    cat <<EOF >"${RUNTIME}/docker-compose.yaml"
---
services:
  server:
    image: docker.io/teddysun/xray:${XRAY[VERSION]:1}
    restart: always
    ports: []
    volumes:
      - "./config.json:/etc/xray/config.json"
EOF
fi

if [[ ! -f "${RUNTIME}/config.json" ]]; then
    cat <<EOF | jq -S . >"${RUNTIME}/config.json"
{
  "inbounds": [
    {
      "port": ${XRAY[PORT]},
      "protocol": "${XRAY[PROTOCOL]}"
    }
  ],
  "log": {
    "loglevel": "warning"
  },
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

    if [[ ${PROTOCOL} == shadowsocks ]]; then
        yq -i '.services.server.ports += "'"${XRAY[PORT]}":8388'/tcp"' "${RUNTIME}/docker-compose.yaml"
        yq -i '.services.server.ports += "'"${XRAY[PORT]}":8388'/udp"' "${RUNTIME}/docker-compose.yaml"

        jq . "${RUNTIME}/config.json" |
            jq ".inbounds[0].port=8388" |
            jq --arg value "${XRAY[SHADOWSOCKS_METHOD]}" '.inbounds[0].settings.method=$value' |
            jq --arg value "${XRAY[SHADOWSOCKS_PASSWORD]}" '.inbounds[0].settings.password=$value' |
            jq --arg value "${XRAY[SHADOWSOCKS_NETWORK]}" '.inbounds[0].settings.network=$value' |
            jq -S . |
            sponge "${RUNTIME}/config.json"
        if [[ ${XRAY[SHADOWSOCKS_METHOD]} == 2022-blake3* ]]; then
            #shellcheck disable=SC2086
            jq . "${RUNTIME}/config.json" |
                jq --arg value "$(echo ${XRAY[SHADOWSOCKS_PASSWORD]} | base64)" '.inbounds[0].settings.password=$value' |
                jq -S . |
                sponge "${RUNTIME}/config.json"
        fi
    fi

    if [[ ${PROTOCOL} == vless ]]; then
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/tcp"' "${RUNTIME}/docker-compose.yaml"
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/udp"' "${RUNTIME}/docker-compose.yaml"

        jq . "${RUNTIME}/config.json" |
            jq ".inbounds[0].settings.decryption=\"none\"" |
            jq ".inbounds[0].settings.clients[0].id=\"${XRAY[VLESS_ID]}\"" |
            jq -S . |
            sponge "${RUNTIME}/config.json"
    fi

    if [[ ${PROTOCOL} == vmess ]]; then
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/tcp"' "${RUNTIME}/docker-compose.yaml"
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/udp"' "${RUNTIME}/docker-compose.yaml"

        jq . "${RUNTIME}/config.json" |
            jq ".inbounds[0].settings.clients[0].alterId=0" |
            jq ".inbounds[0].settings.clients[0].id=\"${XRAY[VMESS_ID]}\"" |
            jq ".inbounds[0].settings.clients[0].security=\"auto\"" |
            jq ".inbounds[0].settings.disableInsecureEncryption=true" |
            jq -S . |
            sponge "${RUNTIME}/config.json"
    fi

    if [[ ${STREAM} == kcp ]]; then
        if [[ ${PROTOCOL} == shadowsocks ]]; then XRAY[KCP_SEED]=""; fi
        jq . "${RUNTIME}/config.json" |
            jq --arg value "${XRAY[KCP_HEADER_TYPE]}" '.inbounds[0].streamSettings.kcpSettings.header.type=$value' |
            jq --arg value "${XRAY[KCP_SEED]}" '.inbounds[0].streamSettings.kcpSettings.seed=$value' |
            jq --argjson value "${XRAY[KCP_CONGESTION]}" '.inbounds[0].streamSettings.kcpSettings.congestion=$value' |
            jq --argjson value "${XRAY[KCP_SERVER_DOWN_CAPACITY]}" '.inbounds[0].streamSettings.kcpSettings.downlinkCapacity=$value' |
            jq --argjson value "${XRAY[KCP_MTU]}" '.inbounds[0].streamSettings.kcpSettings.mtu=$value' |
            jq --argjson value "${XRAY[KCP_SERVER_UP_CAPACITY]}" '.inbounds[0].streamSettings.kcpSettings.uplinkCapacity=$value' |
            jq '.inbounds[0].streamSettings.kcpSettings.readBufferSize=5' |
            jq '.inbounds[0].streamSettings.kcpSettings.tti=30' |
            jq '.inbounds[0].streamSettings.kcpSettings.writeBufferSize=5' |
            jq '.inbounds[0].streamSettings.network="kcp"' |
            jq -S . |
            sponge "${RUNTIME}/config.json"
    fi

    # xray newer than 1.8.24 does not support quic anymore
    if [[ ${STREAM} == quic ]]; then
        jq . "${RUNTIME}/config.json" |
            jq '.inbounds[0].streamSettings.network="quic"' |
            jq --arg value "${XRAY[QUIC_HEADER_TYPE]}" '.inbounds[0].streamSettings.quicSettings.header.type=$value' |
            jq --arg value "${XRAY[QUIC_KEY]}" '.inbounds[0].streamSettings.quicSettings.key=$value' |
            jq --arg value "${XRAY[QUIC_SECURITY]}" '.inbounds[0].streamSettings.quicSettings.security=$value' |
            jq -S . |
            sponge "${RUNTIME}/config.json"
    fi

    if [[ ${STREAM} == xhttp ]]; then
        if [[ ! -f "${RUNTIME}/xray.crt" ]]; then
            openssl req -x509 -newkey rsa:2048 -keyout "${RUNTIME}/xray.key" -out "${RUNTIME}/xray.crt" -days 365 -nodes -subj "/CN=yourdomain.com" 1>/dev/null 2>&1
        fi
        yq -i '.services.server.volumes += "./xray.crt:/etc/xray/certs/xray.crt"' "${RUNTIME}/docker-compose.yaml"
        yq -i '.services.server.volumes += "./xray.key:/etc/xray/certs/xray.key"' "${RUNTIME}/docker-compose.yaml"

        jq . "${RUNTIME}/config.json" |
            jq '.inbounds[0].streamSettings.network="xhttp"' |
            jq '.inbounds[0].streamSettings.security="tls"' |
            jq '.inbounds[0].streamSettings.tlsSettings.certificates[0].certificateFile="/etc/xray/certs/xray.crt"' |
            jq '.inbounds[0].streamSettings.tlsSettings.certificates[0].keyFile="/etc/xray/certs/xray.keyls"' |
            jq -S . |
            sponge "${RUNTIME}/config.json"
    fi
fi
