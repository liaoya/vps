#!/bin/bash
#shellcheck disable=SC2312

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

_check_param SHADOWSOCKS_SERVER

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    envsubst "$(env | sort | sed -e 's/=.*//' -e 's/^/\$/g')" <"${_THIS_DIR}/docker-compose.tpl.yaml" >"${_THIS_DIR}/docker-compose.yaml"
    if [[ -n ${SHADOWSOCKS[SIP003_PLUGIN]} ]]; then
        if [[ ${SHADOWSOCKS[SIP003_PLUGIN]} == "xray-plugin" && -x "${ROOT_DIR}/xray-plugin_linux_amd64" ]]; then
            yq '.services.sslocal.volumes += "../xray-plugin_linux_amd64:/usr/local/bin/xray-plugin"' "${_THIS_DIR}/docker-compose.yaml" | sponge "${_THIS_DIR}/docker-compose.yaml"
        elif [[ ${SHADOWSOCKS[SIP003_PLUGIN]} == "v2ray-plugin" && -x "${ROOT_DIR}/v2ray-plugin_linux_amd64" ]]; then
            yq '.services.sslocal.volumes += "../v2ray-plugin_linux_amd64:/usr/local/bin/v2ray-plugin"' "${_THIS_DIR}/docker-compose.yaml" | sponge "${_THIS_DIR}/docker-compose.yaml"
        else
            echo "Unkown ${SHADOWSOCKS[SIP003_PLUGIN]}"
            exit 1
        fi
    fi
fi

if [[ ! -f "${_THIS_DIR}/ss-local.json" ]]; then
    jq . "${_THIS_DIR}/ss-local-tpl.json" |
        jq --arg value "${SHADOWSOCKS[SHADOWSOCKS_SERVER]}" '.servers[0].address=$value' |
        jq --arg value "${SHADOWSOCKS[SHADOWSOCKS_METHOD]}" '.servers[0].method=$value' |
        jq --arg value "${SHADOWSOCKS[SHADOWSOCKS_PASSWORD]}" '.servers[0].password=$value' |
        jq ".servers[0].port=${SHADOWSOCKS[SHADOWSOCKS_PORT]}" |
        jq -S . >"${_THIS_DIR}/ss-local.json"
    if [[ ${SHADOWSOCKS[SHADOWSOCKS_METHOD]} == 2022-blake3* ]]; then
        #shellcheck disable=SC2086
        jq . "${_THIS_DIR}/ss-local.json" |
            jq --arg value "$(echo ${SHADOWSOCKS[SHADOWSOCKS_PASSWORD]} | base64)" '.servers[0].password=$value' |
            jq -S . |
            sponge "${_THIS_DIR}/ss-local.json"
    fi
    if [[ -n ${SHADOWSOCKS[SIP003_PLUGIN]} ]]; then
        jq . "${_THIS_DIR}/ss-local.json" |
            jq --arg value "${SHADOWSOCKS[SIP003_PLUGIN]}" '.servers[0] |= . + {plugin: $value}' |
            jq --arg value "${SHADOWSOCKS[SIP003_PLUGIN_OPTS]}" '.servers[0] |= . + {plugin_opts: $value}' |
            jq -S . |
            sponge "${_THIS_DIR}/ss-local.json"
    fi
fi

unset -v _THIS_DIR
