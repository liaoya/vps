#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    cat <<EOF >"${_THIS_DIR}/docker-compose.yaml"
---
version: "3"

services:
  client:
    image: docker.io/teddysun/xray:${XRAY[VERSION]:1}
    ports:
      - 1080:1080
      - 1081:1081
    restart: always
    volumes:
      - "./config.json:/etc/xray/config.json"
EOF
fi

if [[ ! -f "${_THIS_DIR}/config.json" ]]; then
    cp "${_THIS_DIR}/client.tpl.json" "${_THIS_DIR}/config.json"

    jq . "${_THIS_DIR}/config.json" |
        jq --arg value "${XRAY[PROTOCOL]}" '.outbounds[2].protocol=$value' |
        jq -S . |
        sponge "${_THIS_DIR}/config.json"

    if [[ ${PROTOCOL} == shadowsocks ]]; then
        jq . "${_THIS_DIR}/config.json" |
            jq '.outbounds[2].mux.concurrency=4' |
            jq '.outbounds[2].mux.enabled=false' |
            jq --arg value "${XRAY[SERVER]}" '.outbounds[2].settings.servers[0].address=$value' |
            jq --argjson value "${XRAY[PORT]}" '.outbounds[2].settings.servers[0].port=$value' |
            jq --arg value "${XRAY[SHADOWSOCKS_METHOD]}" '.outbounds[2].settings.servers[0].method=$value' |
            jq --arg value "${XRAY[SHADOWSOCKS_PASSWORD]}" '.outbounds[2].settings.servers[0].password=$value' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
        if [[ ${XRAY[SHADOWSOCKS_METHOD]} == 2022-blake3* ]]; then
            #shellcheck disable=SC2086
            jq . "${_THIS_DIR}/config.json" |
                jq --arg value "$(echo ${XRAY[SHADOWSOCKS_PASSWORD]} | base64)" '.outbounds[2].settings.servers[0].password=$value' |
                jq -S . |
                sponge "${_THIS_DIR}/config.json"
        fi
    fi

    if [[ ${PROTOCOL} == vless ]]; then
        jq . "${_THIS_DIR}/config.json" |
            jq --arg value "${XRAY[SERVER]}" '.outbounds[2].settings.vnext[0].address=$value' |
            jq --argjson value "${XRAY[PORT]}" '.outbounds[2].settings.vnext[0].port=$value' |
            jq '.outbounds[2].settings.vnext[0].users[0].encryption="none"' |
            jq --arg value "${XRAY[VLESS_ID]}" '.outbounds[2].settings.vnext[0].users[0].id=$value' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi

    if [[ ${PROTOCOL} == vmess ]]; then
        jq . "${_THIS_DIR}/config.json" |
            jq --arg value "${XRAY[SERVER]}" '.outbounds[2].settings.vnext[0].address=$value' |
            jq --argjson value "${XRAY[PORT]}" '.outbounds[2].settings.vnext[0].port=$value' |
            jq '.outbounds[2].settings.vnext[0].users[0].alterId=0' |
            jq --arg value "${XRAY[VMESS_ID]}" '.outbounds[2].settings.vnext[0].users[0].id=$value' |
            jq '.outbounds[2].settings.vnext[0].users[0].security="auto"' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi

    if [[ ${STREAM} == kcp ]]; then
        if [[ ${PROTOCOL} == shadowsocks ]]; then XRAY[KCP_SEED]=""; fi
        jq . "${_THIS_DIR}/config.json" |
            jq --arg value "${XRAY[KCP_HEADER_TYPE]}" '.outbounds[2].streamSettings.kcpSettings.header.type=$value' |
            jq --arg value "${XRAY[KCP_SEED]}" '.outbounds[2].streamSettings.kcpSettings.seed=$value' |
            jq --argjson value "${XRAY[KCP_CONGESTION]}" '.outbounds[2].streamSettings.kcpSettings.congestion=$value' |
            jq --argjson value "${XRAY[KCP_CLIENT_DOWN_CAPACITY]}" '.outbounds[2].streamSettings.kcpSettings.downlinkCapacity=$value' |
            jq --argjson value "${XRAY[KCP_MTU]}" '.outbounds[2].streamSettings.kcpSettings.mtu=$value' |
            jq --argjson value "${XRAY[KCP_CLIENT_UP_CAPACITY]}" '.outbounds[2].streamSettings.kcpSettings.uplinkCapacity=$value' |
            jq '.outbounds[2].streamSettings.kcpSettings.readBufferSize=5' |
            jq '.outbounds[2].streamSettings.kcpSettings.tti=30' |
            jq '.outbounds[2].streamSettings.kcpSettings.writeBufferSize=5' |
            jq '.outbounds[2].streamSettings.network="kcp"' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi

    if [[ ${STREAM} == quic ]]; then
        jq . "${_THIS_DIR}/config.json" |
            jq '.outbounds[2].streamSettings.network="quic"' |
            jq --arg value "${XRAY[QUIC_HEADER_TYPE]}" '.outbounds[2].streamSettings.quicSettings.header.type=$value' |
            jq --arg value "${XRAY[QUIC_KEY]}" '.outbounds[2].streamSettings.quicSettings.key=$value' |
            jq --arg value "${XRAY[QUIC_SECURITY]}" '.outbounds[2].streamSettings.quicSettings.security=$value' |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi
fi

unset -v _THIS_DIR
