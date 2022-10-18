#!/bin/bash

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
    if [[ -f "${ROOT_DIR}/.options" ]]; then
        XRAY[${_upper}]=$(grep -i "^${_lower}=" "${ROOT_DIR}/.options" | cut -d'=' -f2-)
    fi
    if [[ -n ${!_upper} ]]; then
        XRAY[${_upper}]=${XRAY[${_upper}]:-${!_upper}}
    fi
    if [[ $# -gt 1 ]]; then
        XRAY[${_upper}]=${XRAY[${_upper}]:-${2}}
    fi
    XRAY[${_upper}]=${XRAY[${_upper}]:-""}
}

_read_param alterid $((RANDOM % 70 + 30))
_read_param port $((RANDOM % 10000 + 20000))
_read_param uuid "$(cat /proc/sys/kernel/random/uuid)"
_read_param mux_concurrency 4
_read_param server ""
_read_param xray_version

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

_check_param MKCP_PORT MKCP_SEED MKCP_UUID PORT UUID XRAY_VERSION

{
    tracestate=$(shopt -po xtrace) || true
    set +x
    for key in "${!XRAY[@]}"; do echo "$key => ${XRAY[$key]}"; done
    [[ -n "${tracestate}" ]] && eval "${tracestate}"
} | sort

if [[ -z ${XRAY[XRAY_VERSION]} ]]; then
    XRAY_VERSION=${XRAY_VERSION:-$(curl -s "https://api.github.com/repos/teddysun/xray-plugin/tags" | jq -r '.[0].name')}
    XRAY_VERSION=${XRAY_VERSION:-v1.6.0}
    XRAY[XRAY_VERSION]="${XRAY_VERSION}"
fi

export XRAY_IMAGE_VERSION=${XRAY[XRAY_VERSION]:1}
