#!/bin/bash
#shellcheck disable=SC1090,SC1091

set -ae

ROOT_DIR=$(readlink -f "${BASH_SOURCE[0]}")
ROOT_DIR=$(dirname "${ROOT_DIR}")
export ROOT_DIR

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") OPTIONS
    -h, show the help
    -v, verbose mode
    -c, clean the previous. ${CLEAN:+the default is ${CLEAN}}
    -d RUNTIME, the directory for running. ${RUNTIME:+the default is ${RUNTIME}}
    -f EVNFILE, The environment file. ${EVNFILE:+the default is ${EVNFILE}}
    -m MODE <server|client>, ${MODE:+the default is ${MODE}}
    -p PROTOCOL <shadowsocks|vless>, xray protocol. ${PROTOCOL:+the default is ${PROTOCOL}}
    -s STREAM [kcp|xhttp], xray stream. ${STREAM:+the default is ${STREAM}}
Example:
# Create the server
    $(basename "${BASH_SOURCE[0]}") -h
    SHADOWSOCKS_METHOD=aes-256-gcm SHADOWSOCKS_PASSWORD= $(basename "${BASH_SOURCE[0]}") -m server -p shadowsocks -s kcp
    SHADOWSOCKS_METHOD=aes-128-gcm SHADOWSOCKS_PASSWORD= $(basename "${BASH_SOURCE[0]}") -m server -p shadowsocks -s xhttp
    VLESS_ID=$(cat /proc/sys/kernel/random/uuid) KCP_SEED= $(basename "${BASH_SOURCE[0]}") -m server -p vless -s kcp
    VLESS_ID=$(cat /proc/sys/kernel/random/uuid) $(basename "${BASH_SOURCE[0]}") -m server -p vless -s xhttp
# Create the client
    $(basename "${BASH_SOURCE[0]}") -m client -f <option file>
# Use the current options to create environment
    $(basename "${BASH_SOURCE[0]}") -f .env
EOF
}

declare -A XRAY
export XRAY

CLEAN=${CLEAN:-0}
EVNFILE=${EVNFILE:-}
MODE=${MODE:-}
PROTOCOL=${PROTOCOL:-}
RUNTIME=${RUNTIME:-}
STREAM=${STREAM:-}

while getopts ":hvcd:f:m:p:s:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    v)
        set -x
        export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        ;;
    c)
        CLEAN=1
        ;;
    d)
        RUNTIME=$(readlink -f "${OPTARG}")
        ;;
    f)
        EVNFILE=$(readlink -f "${OPTARG}")
        ;;
    m)
        MODE=${OPTARG,,}
        ;;
    p)
        PROTOCOL=${OPTARG,,}
        ;;
    s)
        STREAM=${OPTARG,,}
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done

if [[ -z ${EVNFILE} ]]; then
    if [[ -f ${ROOT_DIR}/${PROTOCOL}-${STREAM}.env ]]; then
        EVNFILE=${ROOT_DIR}/${PROTOCOL}-${STREAM}.env
    else
        EVNFILE=${ROOT_DIR}/.$(hostname)-${PROTOCOL}-${STREAM}.env
    fi
fi
if [[ ${MODE} == client && ! -e ${EVNFILE} ]]; then
    echo "${EVNFILE} must exist for ${MODE}"
    exit 1
fi
if [[ ! -e ${EVNFILE} ]]; then
    touch "${EVNFILE}"
else
    source "${EVNFILE}"
fi

for key in MODE PROTOCOL STREAM; do
    if [[ -n ${!key} ]]; then
        export ${key}=${!key}
        export ${key,,}=${!key}
    else
        _lower=${key,,}
        if [[ -n ${!_lower} ]]; then
            export ${key^^}="${!_lower}"
        fi
        set -e _lower
    fi
done

_variables=(MODE PROTOCOL STREAM)
for _var in "${_variables[@]}"; do
    if [[ -z ${!key} ]]; then
        echo "${_variables[@]}" "are required and ${_var} is missing"
        exit 1
    fi
done

if [[ -z ${RUNTIME} ]]; then
    RUNTIME=${PROTOCOL}-${STREAM}-${MODE}
    export RUNTIME=${ROOT_DIR}/${RUNTIME}
fi
if [[ -d "${RUNTIME}" && ${CLEAN} -eq 0 ]]; then
    echo "${RUNTIME} exists"
    exit 1
fi
rm -fr "${RUNTIME}" || true
mkdir -p "${RUNTIME}" || true

_commands=(docker jq sponge yq)
for _cmd in "${_commands[@]}"; do
    if ! command -v "${_cmd}" 1>/dev/null 2>&1; then
        echo "${_commands[@]}" "are required and ${_cmd} is missing"
        exit 1
    fi
done

if [[ -z ${MODE} || -z ${PROTOCOL} ]]; then
    print_usage
    exit 1
fi
if [[ -f "${ROOT_DIR}/pre.sh" ]]; then source "${ROOT_DIR}/pre.sh"; fi

if [[ -f "${ROOT_DIR}/${XRAY[MODE]}/env.sh" ]]; then source "${ROOT_DIR}/${XRAY[MODE]}/env.sh"; fi
cp "${EVNFILE}" "${RUNTIME}"/.env
cp "${ROOT_DIR}/run.sh" "${RUNTIME}"/

if [[ -f "${ROOT_DIR}/post.sh" ]]; then source "${ROOT_DIR}/post.sh"; fi
