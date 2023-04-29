#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    envsubst "$(env | sort | sed -e 's/=.*//' -e 's/^/\$/g')" <"${_THIS_DIR}/docker-compose.tpl.yaml" >"${_THIS_DIR}/docker-compose.yaml"
    if [[ -n ${SHADOWSOCKS[SIP003_PLUGIN]} ]]; then
        if [[ ${SHADOWSOCKS[SIP003_PLUGIN]} == "xray-plugin" && -x "${ROOT_DIR}/xray-plugin_linux_amd64" ]]; then
            yq '.services.ssserver.volumes += "../xray-plugin_linux_amd64:/usr/local/bin/xray-plugin"' "${_THIS_DIR}/docker-compose.yaml" | sponge "${_THIS_DIR}/docker-compose.yaml"
        elif [[ ${SHADOWSOCKS[SIP003_PLUGIN]} == "v2ray-plugin" && -x "${ROOT_DIR}/v2ray-plugin_linux_amd64" ]]; then
            yq '.services.ssserver.volumes += "../v2ray-plugin_linux_amd64:/usr/local/bin/v2ray-plugin"' "${_THIS_DIR}/docker-compose.yaml" | sponge "${_THIS_DIR}/docker-compose.yaml"
        else
            echo "Unkown ${SHADOWSOCKS[SIP003_PLUGIN]}"
            exit 1
        fi
    fi
fi

if [[ ! -f "${_THIS_DIR}/ss-server.json" ]]; then
    jq . "${_THIS_DIR}/ssserver-rust.tpl.json" |
        jq --arg value "${SHADOWSOCKS[SHADOWSOCKS_METHOD]}" '.method=$value'  |
        jq --arg value "${SHADOWSOCKS[SHADOWSOCKS_PASSWORD]}" '.password=$value'
        jq -S . >"${_THIS_DIR}/ss-server.json"
    if [[ -n ${SHADOWSOCKS[SIP003_PLUGIN]} ]]; then
        jq --arg value "${SHADOWSOCKS[SIP003_PLUGIN]}" '. + {plugin: $value}' "${_THIS_DIR}/ss-server.json" |
            jq --arg value "server${SHADOWSOCKS[SIP003_PLUGIN_OPTS]:+;${SHADOWSOCKS[SIP003_PLUGIN_OPTS]}}" '. + {plugin_opts: $value}' |
            jq -S . | sponge "${_THIS_DIR}/ss-server.json"
    fi
fi

unset -v _THIS_DIR
