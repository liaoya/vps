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

_read_param mode
_read_param port $((RANDOM % 10000 + 20000))
_read_param protocol
_read_param transport
_read_param version

if [[ ${PROTOCOL} == shadowsocks ]]; then
    _read_param shadowsocks_method "2022-blake3-aes-256-gcm"
    _read_param shadowsocks_network "tcp,udp"
    _read_param shadowsocks_password "$(tr -cd '[:alnum:]' </dev/urandom | fold -w30 | head -n1)"
fi

if [[ ${PROTOCOL} == vmess ]]; then
    _read_param vmess_id "$(cat /proc/sys/kernel/random/uuid)"
    _read_param vmess_port $((RANDOM % 10000 + 20000))
    _read_param vmess_kcp_header_type dtls
    _read_param mkcp_seed "$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)"
fi

if [[ ${TRANSPORT} == kcp ]]; then
    _read_param kcp_client_down_capacity 200
    _read_param kcp_client_up_capacity 50
    _read_param kcp_header_type dtls
    _read_param kcp_server_down_capacity 200
    _read_param kcp_server_up_capacity 200
    if [[ ${PROTOCOL} != shadowsocks ]]; then
        _read_param kcp_seed "$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)"
    fi
fi

if [[ -z ${XRAY[VERSION]} ]]; then
    VERSION=${VERSION:-$(curl -s https://api.github.com/repos/xtls/xray-core/releases/latest | jq -r .tag_name)}
    VERSION=${VERSION:-v1.7.5}
    XRAY[VERSION]="${VERSION}"
fi

{
    for key in "${!XRAY[@]}"; do echo "${key} => ${XRAY[${key}]}"; done
} | sort

_check_param MODE PORT PROTOCOL VERSION
export XRAY_PORT=${XRAY[PORT]}
export XRAY_VERSION=${XRAY[VERSION]:1}

[[ -n "${tracestate}" ]] && eval "${tracestate}"
