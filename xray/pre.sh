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
    if [[ -n ${!_upper} ]]; then
        XRAY["${_upper}"]=${XRAY["${_upper}"]:-${!_upper}}
    fi
    if [[ -f "${EVNFILE}" ]]; then
        XRAY["${_upper}"]=${XRAY["${_upper}"]:-$(grep -i "^${_lower}=" "${EVNFILE}" | cut -d'=' -f2-)}
    fi
    if [[ $# -gt 1 && -n ${2} ]]; then
        XRAY["${_upper}"]=${XRAY["${_upper}"]:-${2}}
    fi
    XRAY["${_upper}"]=${XRAY["${_upper}"]:-""}
}

tracestate=$(shopt -po xtrace) || true
set +x

_read_param mode "${MODE}"
_read_param port $((RANDOM % 10000 + 20000))
_read_param protocol "${PROTOCOL}"
export PROTOCOL=${XRAY[PROTOCOL]}
_read_param stream
export STREAM=${XRAY[STREAM]}
_read_param version

if [[ ${MODE} == server ]]; then
    _read_param server "${SERVER:-$(curl -sL https://httpbin.org/get | jq -r .origin)}"
else
    unset -v SERVER
    _read_param server
fi

if [[ ${PROTOCOL} == shadowsocks ]]; then
    _read_param shadowsocks_method "2022-blake3-aes-256-gcm"
    if [[ ${STREAM} == kcp ]]; then
        _read_param shadowsocks_network "tcp"
    else
        _read_param shadowsocks_network "tcp,udp"
    fi
    _read_param shadowsocks_password "$(tr -cd '[:alnum:]' </dev/urandom | fold -w32 | head -n1)"
    if [[ ${XRAY[SHADOWSOCKS_METHOD]} == 2022-blake3* ]]; then
        if [[ ${#XRAY[SHADOWSOCKS_PASSWORD]} -ne 32 ]]; then
            echo "The password lenght must be 32 when using 2022-blake3"
            exit 1
        fi
    fi
fi

if [[ ${PROTOCOL} == vless ]]; then
    _read_param vless_id "$(cat /proc/sys/kernel/random/uuid)"
fi

if [[ ${PROTOCOL} == vmess ]]; then
    _read_param vmess_id "$(cat /proc/sys/kernel/random/uuid)"
fi

if [[ ${STREAM} == kcp ]]; then
    _read_param kcp_client_down_capacity 200
    _read_param kcp_client_up_capacity 50
    _read_param kcp_congestion false
    _read_param kcp_header_type dtls
    _read_param kcp_mtu 1350
    _read_param kcp_server_down_capacity 200
    _read_param kcp_server_up_capacity 200
    if [[ ${PROTOCOL} != shadowsocks ]]; then
        _read_param kcp_seed "$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)"
    else
        _read_param kcp_seed ""
    fi
fi

if [[ ${STREAM} == quic ]]; then
    _read_param quic_header_type dtls
    _read_param quic_key "$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)"
    _read_param quic_security aes-128-gcm
fi

# Hard code the version since there're a lot of change for new version
XRAY_VERSION=v1.8.24
if [[ -z ${XRAY[VERSION]} ]]; then
    XRAY_VERSION=${XRAY_VERSION:-$(curl -s https://api.github.com/repos/xtls/xray-core/releases/latest | jq -r .tag_name)}
    XRAY[VERSION]="${XRAY_VERSION}"
fi

{
    for key in "${!XRAY[@]}"; do echo "${key} => ${XRAY[${key}]}"; done
} | sort

_check_param MODE PORT PROTOCOL SERVER VERSION

for _key in "${!XRAY[@]}"; do
    if [[ -n ${XRAY[${_key}]} ]]; then
        sed -i -e "/^${_key,,}=/d" -e "/^${_key^^}=/d" "${EVNFILE}"
    fi
done

for _key in "${!XRAY[@]}"; do
    if [[ -n ${XRAY[${_key}]} ]]; then
        echo "${_key,,}=${XRAY[${_key}]}" >>"${EVNFILE}"
    fi
done
sort "${EVNFILE}" | sponge "${EVNFILE}"

[[ -n "${tracestate}" ]] && eval "${tracestate}"
