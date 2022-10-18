#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

export XRAY_MKCP_PORT=${XRAY[MKCP_PORT]}
export XRAY_PORT=${XRAY[PORT]}

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    envsubst "$(env | sort | sed -e 's/=.*//' -e 's/^/\$/g')" <"${_THIS_DIR}/docker-compose.tpl.yaml" | tee "${_THIS_DIR}/docker-compose.yaml"
fi

if [[ ! -f "${_THIS_DIR}/config.json" ]]; then
    #shellcheck disable=SC2002
    cat "${_THIS_DIR}/server.tpl.json" |
        jq ".inbounds[0].port=${XRAY[PORT]}" |
        jq ".inbounds[0].settings.clients[0].alterId=${XRAY[ALTERID]}" |
        jq ".inbounds[0].settings.clients[0].id=\"${XRAY[UUID]}\"" |
        jq ".inbounds[1].port=${XRAY[MKCP_PORT]}" |
        jq ".inbounds[1].settings.clients[0].alterId=${XRAY[MKCP_ALTERID]}" |
        jq ".inbounds[1].settings.clients[0].id=\"${XRAY[MKCP_UUID]}\"" |
        jq ".inbounds[1].streamSettings.kcpSettings.downlinkCapacity=${XRAY[MKCP_SERVER_DOWN_CAPACITY]}" |
        jq ".inbounds[1].streamSettings.kcpSettings.header.type=\"${XRAY[MKCP_HEADER_TYPE]}\"" |
        jq ".inbounds[1].streamSettings.kcpSettings.seed=\"${XRAY[MKCP_SEED]}\"" |
        jq ".inbounds[1].streamSettings.kcpSettings.uplinkCapacity=${XRAY[MKCP_SERVER_UP_CAPACITY]}" |
        jq -S '.' >"${_THIS_DIR}/config.json"
fi

unset -v _THIS_DIR
