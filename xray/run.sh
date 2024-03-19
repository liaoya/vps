#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

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

function print_usage() {
    local _candidate _item
    #shellcheck disable=SC2010
    while IFS= read -r _item; do
        _candidate=${_candidate:+${_candidate}|}$(basename "${_item}")
    done < <(ls -1d "${ROOT_DIR}"/*/)
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") OPTIONS <clean|restart|start|stop>
    -h, show the help
    -v, verbose mode
    -l LOGLEVEL [warning|info|debug|error|none]
Example:
    $(basename "${BASH_SOURCE[0]}") clean
EOF
}

LOGLEVEL=${LOGLEVEL:-warning}
while getopts ":hvl:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    v)
        set -x
        export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        ;;
    l)
        LOGLEVEL=${OPTARG}
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

for cmd in docker jq sponge yq; do
    if ! command -v "${cmd}" 1>/dev/null 2>&1; then
        echo "${cmd} is required"
        exit 1
    fi
done

for item in config.json docker-compose.yaml; do
    if [[ ! -f "${_THIS_DIR}/${item}" ]]; then
        echo "${_THIS_DIR}/${item} is required"
        exit 1
    fi
done

COMPOSE_PROJECT_NAME=xray-$(basename "${_THIS_DIR}")
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME/-server/}
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME/-client/}
export COMPOSE_PROJECT_NAME

declare -A XRAY
export XRAY

while read -r line; do
    key=$(echo "${line}" | cut -d= -f1)
    value=$(echo "${line}" | cut -d= -f2)
    XRAY["${key^^}"]="${value}"
done <"${_THIS_DIR}/.options"

if [[ $(jq -r '.log.loglevel' "${_THIS_DIR}/config.json") != "${LOGLEVEL}" ]]; then
    jq --arg value "${LOGLEVEL}" '.log.loglevel=$value' "${_THIS_DIR}/config.json" | sponge "${_THIS_DIR}/config.json"
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" stop
fi

if [[ ${1} == clean ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" down -v
    while IFS= read -r _container; do
        docker container rm -f -v "${_container}"
    done < <(docker ps -a --format '{{.Names}}' | grep -E "^${COMPOSE_PROJECT_NAME}")
    _delete_firewall_port "${XRAY[PORT]}"
elif [[ ${1} == start ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" up -d
    if [[ ${XRAY[MODE]} == server ]]; then
        _add_firewall_port "${XRAY[PORT]}"
    fi
elif [[ ${1} == stop ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" stop
elif [[ ${1} == restart ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" restart
    if [[ ${XRAY[MODE]} == server ]]; then
        _add_firewall_port "${XRAY[PORT]}"
    fi
else
    echo "${1} is unknown operation"
    exit 1
fi
