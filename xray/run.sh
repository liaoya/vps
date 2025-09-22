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

if [[ $# -ne 1 ]]; then
    print_usage
    exit 1
fi

_commands=(docker jq sponge yq)
for _cmd in "${_commands[@]}"; do
    if ! command -v "${_cmd}" 1>/dev/null 2>&1; then
        echo "${_commands[@]}" "are required and ${_cmd} is missing"
        exit 1
    fi
done

for item in config.json docker-compose.yaml; do
    if [[ ! -f "${_THIS_DIR}/${item}" ]]; then
        echo "${_THIS_DIR}/${item} is required"
        exit 1
    fi
done

if [[ $(jq -r '.log.loglevel' "${_THIS_DIR}/config.json") != "${LOGLEVEL}" ]]; then
    jq --arg value "${LOGLEVEL}" '.log.loglevel=$value' "${_THIS_DIR}/config.json" | sponge "${_THIS_DIR}/config.json"
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" stop
fi

# shellcheck disable=SC2046
mapfile -t _PORTS < <(yq .services.server.ports "${_THIS_DIR}"/docker-compose.yaml | tr -d '[:alpha:]- \/' | cut -d: -f1 | sort | uniq)
_IS_SERVER=$(yq '.services | has("server")' "${_THIS_DIR}/docker-compose.yaml")

if [[ ${1} == clean ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" down -v
    _delete_firewall_port "${_PORTS[@]}"
elif [[ ${1} == start ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" up -d
    if [[ ${_IS_SERVER} == true ]]; then
        _add_firewall_port "${_PORTS[@]}"
    fi
elif [[ ${1} == stop ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" stop
elif [[ ${1} == restart ]]; then
    docker compose -f "${_THIS_DIR}/docker-compose.yaml" restart
    if [[ ${_IS_SERVER} == true ]]; then
        _add_firewall_port "${_PORTS[@]}"
    fi
else
    echo "${1} is unknown operation"
    exit 1
fi
