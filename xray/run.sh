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
Usage: $(basename "${BASH_SOURCE[0]}") OPTIONS <clean|restart|start|stop> <${_candidate}> <shadowsocks|vmess|vless> <kcp|quic>
    -h, show the help
    -v, verbose mode
    -f EVNFILE, The environment file. ${EVNFILE:+the default is ${EVNFILE}}
    -m MODE, server or client. ${MODE:+the default is ${MODE}}
    -p PROTOCOL, xray protocol, either of shadowsocks, vmess
    -s STREAM, xray stream, either of empty, kcp
Example:
    $(basename "${BASH_SOURCE[0]}") clean
    $(basename "${BASH_SOURCE[0]}") -m server -p shadowsocks start
    $(basename "${BASH_SOURCE[0]}") -m server -p shadowsocks -s kcp start
    $(basename "${BASH_SOURCE[0]}") restart
    $(basename "${BASH_SOURCE[0]}") stop
EOF
}

function _add_firewall_port() {
    while (($#)); do
        if command -v ufw 1>/dev/null 2>&1; then
            if ! sudo ufw status numbered | sed '1,4d' | sed -s 's/\[ /\[/g' | tr -d '[]' | cut -d' ' -f2 | grep -s -q -w "${1}"; then
                sudo ufw allow "${1}"
            fi
        fi
        shift
    done
}

function _delete_firewall_port() {
    while (($#)); do
        if command -v ufw 1>/dev/null 2>&1; then
            while IFS= read -r num; do
                echo "y" | sudo ufw delete "${num}"
            done < <(sudo ufw status numbered | sed '1,4d' | sed -s 's/\[ /\[/g' | tr -d '[]' | cut -d' ' -f1,2 | grep -w "${1}" | tac | cut -d' ' -f1)
        fi
        shift
    done
}

declare -A XRAY
export XRAY

EVNFILE=${EVNFILE:-"${ROOT_DIR}/.options"}
MODE=${MODE:-}
PROTOCOL=${PROTOCOL:-}
STREAM=${STREAM:-}
VERBOSE=0

while getopts ":hvf:m:p:s:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    v)
        export VERBOSE=1
        set -x
        export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        ;;
    f)
        EVNFILE=$(readlink -f "${OPTARG}")
        ;;
    m)
        MODE=${OPTARG}
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
shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi
OPERATION=$1
for key in EVNFILE MODE PROTOCOL STREAM; do
    if [[ -n ${!key} ]]; then
        export ${key}=${!key}
    fi
done

for cmd in docker docker-compose jq yq; do
    if ! command -v "${cmd}" 1>/dev/null 2>&1; then
        echo "${cmd} is required"
        exit 1
    fi
done

if [[ ${OPERATION} == start ]] && [[ -z ${MODE} || -z ${PROTOCOL} ]]; then
    print_usage
    exit 1
fi

if [[ ${OPERATION} != start && ! -e ${EVNFILE} ]]; then
    echo "${OPERATION} require a env file"
    exit 1
fi

if [[ ! -e ${EVNFILE} ]]; then touch "${EVNFILE}"; fi
if [[ -f "${ROOT_DIR}/pre.sh" ]]; then source "${ROOT_DIR}/pre.sh"; fi

COMPOSE_PROJECT_NAME=$(basename "${ROOT_DIR}")-${XRAY[PROTOCOL]}
export COMPOSE_PROJECT_NAME

if [[ ${OPERATION} == start ]]; then
    if [[ -f "${ROOT_DIR}/${XRAY[MODE]}/env.sh" ]]; then source "${ROOT_DIR}/${XRAY[MODE]}/env.sh"; fi
    docker-compose -f "${ROOT_DIR}/${MODE}/docker-compose.yaml" up -d
    if [[ ${MODE} == server ]]; then
        _add_firewall_port "${XRAY[PORT]}"
    fi
    if [[ -f "${ROOT_DIR}/post.sh" && ${OPERATION} == start ]]; then source "${ROOT_DIR}/post.sh"; fi
    exit 0
fi

if [[ ! -f "${ROOT_DIR}/${XRAY[MODE]}/docker-compose.yaml" ]]; then
    echo "${ROOT_DIR}/${XRAY[MODE]}/docker-compose.yaml does not exist"
    exit 1
fi

if [[ ${OPERATION} == clean ]]; then
    while IFS= read -r _container; do
        docker container rm -f -v "${_container}"
    done < <(docker ps -a --format '{{.Names}}' | grep -E "^${COMPOSE_PROJECT_NAME}")
    #shellcheck disable=SC2086
    while IFS= read -r _dir; do
        if [[ -f "${_dir}clean.sh" ]]; then
            bash "${_dir}clean.sh"
        fi
    done < <(ls -1d ${ROOT_DIR}/*/)
    _delete_firewall_port "${XRAY[PORT]}"
elif [[ ${OPERATION} == stop ]]; then
    docker-compose -f "${ROOT_DIR}/${XRAY[MODE]}/docker-compose.yaml" stop
elif [[ ${OPERATION} == restart ]]; then
    docker-compose -f "${ROOT_DIR}/${XRAY[MODE]}/docker-compose.yaml" restart
    if [[ ${XRAY[MODE]} == server ]]; then
        _add_firewall_port "${XRAY[PORT]}"
    fi
fi
