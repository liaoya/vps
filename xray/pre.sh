#!/bin/bash
#shellcheck disable=SC2312

function _check_param() {
    while (($#)); do
        if [[ -z ${XRAY[$1]} ]]; then
            echo "\${XRAY[$1]} is required"
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
        XRAY["${_upper}"]=$(grep -i "^${_lower}=" "${EVNFILE}" | cut -d'=' -f2-)
    fi
    if [[ -n ${!_upper} ]]; then
        XRAY["${_upper}"]=${XRAY["${_upper}"]:-${!_upper}}
    fi
    if [[ $# -gt 1 ]]; then
        XRAY["${_upper}"]=${XRAY["${_upper}"]:-${2}}
    fi
    XRAY["${_upper}"]=${XRAY["${_upper}"]:-""}
}

tracestate=$(shopt -po xtrace) || true
set +x

_read_param xray_version
_read_param protocol

if [[ ${PROTOCOL} == shadowsocks ]]; then
    _read_param shadowsocks_method "2022-blake3-aes-256-gcm"
    _read_param shadowsocks_password "$(tr -cd '[:alnum:]' </dev/urandom | fold -w30 | head -n1)"
    _read_param shadowsocks_port $((RANDOM % 10000 + 20000))
fi

if [[ ${PROTOCOL} == vmess ]]; then
    _read_param vmess_id "$(cat /proc/sys/kernel/random/uuid)"
    _read_param vmess_port $((RANDOM % 10000 + 20000))
    _read_param vmess_kcp_header_type dtls
    _read_param mkcp_seed "$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)"
fi

{
    for key in "${!XRAY[@]}"; do echo "${key} => ${XRAY[${key}]}"; done
} | sort

if [[ -z ${XRAY[XRAY_VERSION]} ]]; then
    XRAY_VERSION=${XRAY_VERSION:-$(curl -s https://api.github.com/repos/xtls/xray-core/releases/latest | jq -r .tag_name)}
    XRAY_VERSION=${XRAY_VERSION:-v1.7.5}
    XRAY[XRAY_VERSION]="${XRAY_VERSION}"
fi

_check_param XRAY_VERSION PROTOCOL

[[ -n "${tracestate}" ]] && eval "${tracestate}"
