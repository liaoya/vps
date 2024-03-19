#!/bin/bash
#shellcheck disable=SC2312

function _check_param() {
    while (($#)); do
        if [[ -z ${SHADOWSOCKS[$1]} ]]; then
            echo "\${SHADOWSOCKS[$1]} is required"
            exit 1
        fi
        shift 1
    done
}

function _read_param() {
    local _lower _upper
    _lower=${1,,}
    _upper=${1^^}
    #shellcheck disable=SC2154
    if [[ -f "${EVNFILE}" ]]; then
        SHADOWSOCKS["${_upper}"]=$(grep -i "^${_lower}=" "${EVNFILE}" | cut -d'=' -f2-)
    fi
    if [[ -n ${!_upper} ]]; then
        SHADOWSOCKS["${_upper}"]=${SHADOWSOCKS["${_upper}"]:-${!_upper}}
    fi
    if [[ $# -gt 1 ]]; then
        SHADOWSOCKS["${_upper}"]=${SHADOWSOCKS["${_upper}"]:-${2}}
    fi
    SHADOWSOCKS["${_upper}"]=${SHADOWSOCKS["${_upper}"]:-""}
}

tracestate=$(shopt -po xtrace) || true
set +x

_read_param kcptun_port $((RANDOM % 10000 + 20000))
_read_param kcptun_version
_read_param shadowsocks_method 2022-blake3-aes-256-gcm
_read_param shadowsocks_password "$(tr -cd '[:alnum:]' </dev/urandom | fold -w32 | head -n1)"
_read_param shadowsocks_port $((RANDOM % 10000 + 20000))
_read_param shadowsocks_rust_version
_read_param shadowsocks_server "$(curl -sL https://httpbin.org/get | jq -r .origin)"
_read_param sip003_plugin_opts ""
_read_param sip003_plugin ""
_read_param v2ray_plugin_version
_read_param xray_plugin_version

if [[ -z ${SHADOWSOCKS[KCPTUN_VERSION]} ]]; then
    KCPTUN_VERSION=${KCPTUN_VERSION:-$(curl -s "https://api.github.com/repos/xtaci/kcptun/tags" | jq -r '.[0].name')}
    KCPTUN_VERSION=${KCPTUN_VERSION:-v20240107}
    SHADOWSOCKS[KCPTUN_VERSION]="${KCPTUN_VERSION}"
fi
if [[ -z ${SHADOWSOCKS[SHADOWSOCKS_RUST_VERSION]} ]]; then
    SHADOWSOCKS_RUST_VERSION=${SHADOWSOCKS_RUST_VERSION:-$(curl -sL "https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')}
    SHADOWSOCKS_RUST_VERSION=${SHADOWSOCKS_RUST_VERSION:-v1.18.2}
    SHADOWSOCKS[SHADOWSOCKS_RUST_VERSION]="${SHADOWSOCKS_RUST_VERSION}"
fi
if [[ -z ${SHADOWSOCKS[V2RAY_PLUGIN_VERSION]} ]]; then
    V2RAY_PLUGIN_VERSION=${V2RAY_PLUGIN_VERSION:-$(curl -s "https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest" | jq -r '.tag_name')}
    V2RAY_PLUGIN_VERSION=${V2RAY_PLUGIN_VERSION:-v1.3.2}
    SHADOWSOCKS[V2RAY_PLUGIN_VERSION]="${V2RAY_PLUGIN_VERSION}"
fi
if [[ -z ${SHADOWSOCKS[XRAY_PLUGIN_VERSION]} ]]; then
    XRAY_PLUGIN_VERSION=${XRAY_PLUGIN_VERSION:-$(curl -s "https://api.github.com/repos/teddysun/xray-plugin/tags" | jq -r '.[0].name')}
    XRAY_PLUGIN_VERSION=${XRAY_PLUGIN_VERSION:-v1.8.9}
    SHADOWSOCKS[XRAY_PLUGIN_VERSION]="${XRAY_PLUGIN_VERSION}"
fi

{
    for key in "${!SHADOWSOCKS[@]}"; do echo "${key} => ${SHADOWSOCKS[${key}]}"; done
} | sort

_check_param KCPTUN_PORT KCPTUN_VERSION SHADOWSOCKS_PASSWORD SHADOWSOCKS_PORT SHADOWSOCKS_RUST_VERSION SHADOWSOCKS_SERVER XRAY_PLUGIN_VERSION

[[ -n "${tracestate}" ]] && eval "${tracestate}"

if [[ -n ${SHADOWSOCKS[SIP003_PLUGIN]} ]]; then
    #shellcheck disable=SC2154
    if [[ ${SHADOWSOCKS[SIP003_PLUGIN]} == xray-plugin ]] && [[ ! -x "${ROOT_DIR}/xray-plugin_linux_amd64" ]]; then
        curl -sL -o - "https://github.com/teddysun/xray-plugin/releases/download/${SHADOWSOCKS[XRAY_PLUGIN_VERSION]}/xray-plugin-linux-amd64-${SHADOWSOCKS[XRAY_PLUGIN_VERSION]}.tar.gz" | tar -C "${ROOT_DIR}" -I gzip -xf -
        chmod a+x "${ROOT_DIR}/xray-plugin_linux_amd64"
        sudo chown "$(id -un):$(id -gn)" "${ROOT_DIR}/xray-plugin_linux_amd64"
    elif [[ ${SHADOWSOCKS[SIP003_PLUGIN]} == v2ray-plugin ]] && [[ ! -x "${ROOT_DIR}/v2ray-plugin_linux_amd64" ]]; then
        curl -sL -o - "https://github.com/shadowsocks/v2ray-plugin/releases/download/${SHADOWSOCKS[V2RAY_PLUGIN_VERSION]}/v2ray-plugin-linux-amd64-${SHADOWSOCKS[V2RAY_PLUGIN_VERSION]}.tar.gz" | tar -C "${ROOT_DIR}" -I gzip -xf -
        chmod a+x "${ROOT_DIR}/v2ray-plugin_linux_amd64"
        sudo chown "$(id -un):$(id -gn)" "${ROOT_DIR}/v2ray-plugin_linux_amd64"
    fi
fi

if [[ ${SHADOWSOCKS[SHADOWSOCKS_METHOD]} == 2022-blake3* ]]; then
    if [[ ${#SHADOWSOCKS[SHADOWSOCKS_PASSWORD]} -ne 32 ]]; then
        echo "The password lenght must be 32 when using 2022-blake3"
        exit 1
    fi
fi

export KCPTUN_PORT=${SHADOWSOCKS[KCPTUN_PORT]}
export KCPTUN_VERSION=${SHADOWSOCKS[KCPTUN_VERSION]}
export SHADOWSOCKS_PORT=${SHADOWSOCKS[SHADOWSOCKS_PORT]}
export SHADOWSOCKS_RUST_VERSION=${SHADOWSOCKS[SHADOWSOCKS_RUST_VERSION]}
