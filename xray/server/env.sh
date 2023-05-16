#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    cat <<EOF >"${_THIS_DIR}/docker-compose.yaml"
---
version: "3"

services:
  server:
    image: docker.io/teddysun/xray:${XRAY[VERSION]:1}
    restart: always
    ports: []
    volumes:
      - "./config.json:/etc/xray/config.json"
EOF
fi

if [[ ! -f "${_THIS_DIR}/config.json" ]]; then
    cat <<EOF | jq -S . >"${_THIS_DIR}/config.json"
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
        yq -i '.services.server.ports += "'"${XRAY[PORT]}":8388'/tcp"' "${_THIS_DIR}/docker-compose.yaml"
        yq -i '.services.server.ports += "'"${XRAY[PORT]}":8388'/udp"' "${_THIS_DIR}/docker-compose.yaml"

        jq . "${_THIS_DIR}/config.json" |
            jq ".inbounds[0].port=8388" |
            jq --arg value "${XRAY[SHADOWSOCKS_METHOD]}" '.inbounds[0].settings.method=$value' |
            jq --arg value "${XRAY[SHADOWSOCKS_PASSWORD]}" '.inbounds[0].settings.password=$value' |
            jq --arg value "${XRAY[SHADOWSOCKS_NETWORK]}" '.inbounds[0].settings.network=$value' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
        if [[ ${XRAY[SHADOWSOCKS_METHOD]} == 2022-blake3* ]]; then
            #shellcheck disable=SC2086
            jq . "${_THIS_DIR}/config.json" |
                jq --arg value "$(echo ${XRAY[SHADOWSOCKS_PASSWORD]} | base64)" '.inbounds[0].settings.password=$value' |
                jq -S . |
                sponge "${_THIS_DIR}/config.json"
        fi
    fi

    if [[ ${PROTOCOL} == vless ]]; then
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/tcp"' "${_THIS_DIR}/docker-compose.yaml"
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/udp"' "${_THIS_DIR}/docker-compose.yaml"
        jq . "${_THIS_DIR}/config.json" |
            jq ".inbounds[0].settings.decryption=\"none\"" |
            jq ".inbounds[0].settings.clients[0].id=\"${XRAY[VLESS_ID]}\"" |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi

    if [[ ${PROTOCOL} == vmess ]]; then
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/tcp"' "${_THIS_DIR}/docker-compose.yaml"
        yq -i '.services.server.ports += "'"${XRAY[PORT]}:${XRAY[PORT]}"'/udp"' "${_THIS_DIR}/docker-compose.yaml"
        jq . "${_THIS_DIR}/config.json" |
            jq ".inbounds[0].settings.clients[0].alterId=0" |
            jq ".inbounds[0].settings.clients[0].id=\"${XRAY[VMESS_ID]}\"" |
            jq ".inbounds[0].settings.clients[0].security=\"auto\"" |
            jq ".inbounds[0].settings.disableInsecureEncryption=true" |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi

    if [[ ${STREAM} == kcp ]]; then
        if [[ ${PROTOCOL} == shadowsocks ]]; then XRAY[KCP_SEED]=""; fi
        jq . "${_THIS_DIR}/config.json" |
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
            sponge "${_THIS_DIR}/config.json"
    fi

    if [[ ${STREAM} == quic ]]; then
        jq . "${_THIS_DIR}/config.json" |
            jq '.inbounds[0].streamSettings.network="quic"' |
            jq --arg value "${XRAY[QUIC_HEADER_TYPE]}" '.inbounds[0].streamSettings.quicSettings.header.type=$value' |
            jq --arg value "${XRAY[QUIC_KEY]}" '.inbounds[0].streamSettings.quicSettings.key=$value' |
            jq --arg value "${XRAY[QUIC_SECURITY]}" '.inbounds[0].streamSettings.quicSettings.security=$value' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi
fi

unset -v _THIS_DIR
