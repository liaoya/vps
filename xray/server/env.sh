#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    envsubst "$(env | sort | sed -e 's/=.*//' -e 's/^/\$/g')" <"${_THIS_DIR}/docker-compose.tpl.yaml" >"${_THIS_DIR}/docker-compose.yaml"
fi

if [[ ! -f "${_THIS_DIR}/config.json" ]]; then
    #shellcheck disable=SC2002
    cat "${_THIS_DIR}/server.tpl.json" |
        jq ".inbounds[0].settings.clients[0].method=\"${XRAY[SHADOWSOCKS_METHOD]}\"" |
        jq ".inbounds[0].settings.clients[0].password=\"${XRAY[SHADOWSOCKS_PASSWORD]}\"" |
        jq ".inbounds[1].settings.clients[0].password=\"${XRAY[SHADOWSOCKS_PASSWORD]}\"" |
        jq ".inbounds[1].streamSettings.kcpSettings.downlinkCapacity=${XRAY[MKCP_SERVER_DOWN_CAPACITY]}" |
        jq ".inbounds[1].streamSettings.kcpSettings.header.type=\"${XRAY[MKCP_HEADER_TYPE]}\"" |
        jq ".inbounds[1].streamSettings.kcpSettings.seed=\"${XRAY[MKCP_SEED]}\"" |
        jq ".inbounds[1].streamSettings.kcpSettings.uplinkCapacity=${XRAY[MKCP_SERVER_UP_CAPACITY]}" |
        jq -S '.' >"${_THIS_DIR}/config.json"
fi

unset -v _THIS_DIR
