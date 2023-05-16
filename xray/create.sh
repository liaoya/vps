#!/bin/bash
#shellcheck disable=SC1090,SC1091

set -ae

ROOT_DIR=$(readlink -f "${BASH_SOURCE[0]}")
ROOT_DIR=$(dirname "${ROOT_DIR}")
export ROOT_DIR

function print_usage() {
    local _candidate _item
    #shellcheck disable=SC2010
    while IFS= read -r _item; do
        _candidate=${_candidate:+${_candidate}|}$(basename "${_item}")
    done < <(ls -1d "${ROOT_DIR}"/*/)
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") OPTIONS
    -h, show the help
    -v, verbose mode
    -d RUNTIME, the directory for running
    -f EVNFILE, The environment file. ${EVNFILE:+the default is ${EVNFILE}}
    -m MODE <${_candidate}>, ${MODE:+the default is ${MODE}}
    -n PREFIX, the prefix name will be used in RUNTIME directory
    -p PROTOCOL <shadowsocks|vmess|vless>, xray protocol
    -s STREAM [kcp|quic], xray stream
Example:
    $(basename "${BASH_SOURCE[0]}") -m server -p shadowsocks
    $(basename "${BASH_SOURCE[0]}") -m server -p shadowsocks -s kcp
EOF
}

declare -A XRAY
export XRAY

EVNFILE=${EVNFILE:-"${ROOT_DIR}/.options"}
MODE=${MODE:-}
PREFIX=""
PROTOCOL=${PROTOCOL:-}
RUNTIME=""
STREAM=${STREAM:-}

while getopts ":hvd:f:m:n:p:s:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    v)
        set -x
        export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        ;;
    d)
        RUNTIME=$(readlink -f "${OPTARG}")
        ;;
    f)
        EVNFILE=$(readlink -f "${OPTARG}")
        ;;
    m)
        MODE=${OPTARG}
        ;;
    n)
        PREFIX=${OPTARG}
        ;;
    p)
        PROTOCOL=${OPTARG}
        ;;
    s)
        STREAM=${OPTARG}
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done

if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi

for key in EVNFILE MODE PROTOCOL STREAM; do
    if [[ -n ${!key} ]]; then
        export ${key}=${!key}
    fi
done

for cmd in docker docker-compose jq sponge yq; do
    if ! command -v "${cmd}" 1>/dev/null 2>&1; then
        echo "${cmd} is required"
        exit 1
    fi
done

if [[ -z ${MODE} || -z ${PROTOCOL} || -z ${EVNFILE} ]]; then
    print_usage
    exit 1
fi

if [[ ! -e ${EVNFILE} ]]; then touch "${EVNFILE}"; fi
if [[ -f "${ROOT_DIR}/pre.sh" ]]; then source "${ROOT_DIR}/pre.sh"; fi

RUNTIME=${XRAY[PROTOCOL]}
if [[ ${PREFIX} ]]; then RUNTIME=${PREFIX}-${RUNTIME}; fi
if [[ -n ${STREAM} ]]; then RUNTIME=${RUNTIME}-${STREAM}; fi
RUNTIME=${RUNTIME}-${XRAY[MODE]}
export RUNTIME=${ROOT_DIR}/${RUNTIME}
mkdir -p "${RUNTIME}"

if [[ -f "${ROOT_DIR}/${XRAY[MODE]}/env.sh" ]]; then source "${ROOT_DIR}/${XRAY[MODE]}/env.sh"; fi
mv "${XRAY[MODE]}/config.json" "${XRAY[MODE]}/docker-compose.yaml" "${RUNTIME}"/
cp "${EVNFILE}" "${RUNTIME}"/.options
cp "${ROOT_DIR}/run.sh" "${RUNTIME}"/

if [[ -f "${ROOT_DIR}/post.sh" ]]; then source "${ROOT_DIR}/post.sh"; fi
