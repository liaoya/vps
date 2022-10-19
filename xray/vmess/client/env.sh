#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

_check_param SERVER

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    envsubst "$(env | sort | sed -e 's/=.*//' -e 's/^/\$/g')" <"${_THIS_DIR}/docker-compose.tpl.yaml" | tee "${_THIS_DIR}/docker-compose.yaml"
fi

if [[ ! -f "${_THIS_DIR}/config.json" ]]; then
    #shellcheck disable=SC2002
    cat "${_THIS_DIR}/client.tpl.json" |
        jq ".outbounds[2].settings.vnext[0].port=${XRAY[PORT]}" |
        jq ".outbounds[2].settings.vnext[0].address=\"${XRAY[SERVER]}\"" |
        jq ".outbounds[2].settings.vnext[0].users[0].id=\"${XRAY[UUID]}\"" |
        jq -S '.' >"${_THIS_DIR}/config.json"
    if [[ ${XRAY[MUX_CONCURRENCY]} -eq 0 ]]; then
        jq 'del(.outbounds[2].mux)' "${_THIS_DIR}/config.json" | sponge "${_THIS_DIR}/config.json"
    fi
fi

if [[ ! -f "${_THIS_DIR}/config-mkcp.json" ]]; then
    #shellcheck disable=SC2002
    cat "${_THIS_DIR}/client-mkcp.tpl.json" |
        jq ".outbounds[2].settings.vnext[0].address=\"${XRAY[SERVER]}\"" |
        jq ".outbounds[2].settings.vnext[0].port=${XRAY[MKCP_PORT]}" |
        jq ".outbounds[2].settings.vnext[0].users[0].id=\"${XRAY[MKCP_UUID]}\"" |
        jq ".outbounds[2].streamSettings.kcpSettings.downlinkCapacity=${XRAY[MKCP_CLIENT_DOWN_CAPACITY]}" |
        jq ".outbounds[2].streamSettings.kcpSettings.header.type=\"${XRAY[MKCP_HEADER_TYPE]}\"" |
        jq ".outbounds[2].streamSettings.kcpSettings.seed=\"${XRAY[MKCP_SEED]}\"" |
        jq ".outbounds[2].streamSettings.kcpSettings.uplinkCapacity=${XRAY[MKCP_CLIENT_UP_CAPACITY]}" |
        jq -S '.' >"${_THIS_DIR}/config-mkcp.json"
    if [[ ${XRAY[MUX_CONCURRENCY]} -eq 0 ]]; then
        jq 'del(.outbounds[2].mux)' "${_THIS_DIR}/config-mkcp.json" | sponge "${_THIS_DIR}/config-mkcp.json"
    fi
fi

unset -v _THIS_DIR
