#!/bin/bash

function _check_param() {
    while (($#)); do
        if [[ -z ${V2RAY[$1]} ]]; then
            echo "\${V2RAY[$1]} is required"
            exit 1
        fi
        shift 1
    done
}

function _read_param() {
    local _lower _upper
    _lower=${1,,}
    _upper=${1^^}
    if [[ -f "${EVNFILE}" ]]; then
        V2RAY[${_upper}]=$(grep -i "^${_lower}=" "${EVNFILE}" | cut -d'=' -f2-)
    fi
    if [[ -n ${!_upper} ]]; then
        V2RAY[${_upper}]=${V2RAY[${_upper}]:-${!_upper}}
    fi
    if [[ $# -gt 1 ]]; then
        V2RAY[${_upper}]=${V2RAY[${_upper}]:-${2}}
    fi
    V2RAY[${_upper}]=${V2RAY[${_upper}]:-""}
}

tracestate=$(shopt -po xtrace) || true
set +x

_read_param alterid $((RANDOM % 70 + 30))
_read_param port $((RANDOM % 10000 + 20000))
_read_param uuid "$(cat /proc/sys/kernel/random/uuid)"
_read_param mux_concurrency 4
_read_param server "$(hostname -I | cut -d' ' -f1)"
_read_param v2ray_version

_read_param mkcp_alterid $((RANDOM % 70 + 30))
_read_param mkcp_client_down_capacity 200
_read_param mkcp_client_up_capacity 50
_read_param mkcp_header_type none
_read_param mkcp_seed "$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)"
# _read_param mkcp_seed ""
_read_param mkcp_port $((RANDOM % 10000 + 20000))
_read_param mkcp_server_down_capacity 200
_read_param mkcp_server_up_capacity 200
_read_param mkcp_uuid "$(cat /proc/sys/kernel/random/uuid)"

{
    for key in "${!V2RAY[@]}"; do echo "$key => ${V2RAY[$key]}"; done
} | sort

if [[ -z ${V2RAY[V2RAY_VERSION]} ]]; then
    V2RAY_VERSION=${V2RAY_VERSION:-$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/tags" | jq -r '.[0].name')}
    V2RAY_VERSION=${V2RAY_VERSION:-v5.1.0}
    V2RAY[V2RAY_VERSION]="${V2RAY_VERSION}"
fi

_check_param MKCP_PORT MKCP_SEED MKCP_UUID PORT UUID V2RAY_VERSION

[[ -n "${tracestate}" ]] && eval "${tracestate}"

export V2RAY_IMAGE_VERSION=${V2RAY[V2RAY_VERSION]:1}
