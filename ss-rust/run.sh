#!/bin/bash
#shellcheck disable=SC1090,SC1091,SC2312

set -ae

ROOT_DIR=$(readlink -f "${BASH_SOURCE[0]}")
ROOT_DIR=$(dirname "${ROOT_DIR}")
export ROOT_DIR

function _check_command() {
    if [[ -z $(command -v "${1}") ]]; then
        echo "Command ${1} is required. Run '$2'"
        return 1
    fi
}

function _add_firewall_port() {
    while (($#)); do
        if ! sudo ufw status numbered | sed '1,4d' | sed -s 's/\[ /\[/g' | tr -d '[]' | cut -d' ' -f2 | grep -s -q -w "${1}"; then
            sudo ufw allow "${1}"
        fi
        shift
    done
}

function _delete_firewall_port() {
    while (($#)); do
        while IFS= read -r num; do
            echo "y" | sudo ufw delete "${num}"
        done < <(sudo ufw status numbered | sed '1,4d' | sed -s 's/\[ /\[/g' | tr -d '[]' | cut -d' ' -f1,2 | grep -w "${1}" | tac | cut -d' ' -f1)
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
Usage: $(basename "${BASH_SOURCE[0]}") options <clean|restart|start|stop> <${_candidate}>
    -h, show the help
    -v, verbose mode
    -f EVNFILE, The environment file. ${EVNFILE:+the default is ${EVNFILE}}
    -m SIP003_PLUGIN_OPTS, sip003 plugin_opts. ${SHADOWSOCKS[SIP003_PLUGIN]:+The default is ${SHADOWSOCKS[SIP003_PLUGIN_OPTS]}}
    -p SIP003_PLUGIN, Shadowsocks sip003 plugin. ${SHADOWSOCKS[SIP003_PLUGIN_OPTS]:+The default is ${SHADOWSOCKS[SIP003_PLUGIN]}}
EOF
}

_check_command docker "sudo apt intall -yq docker.io docker-compose-v2"
_check_command jq "sudo apt intall -yq jq"
_check_command sponge "sudo apt intall -yq moreutils"
_check_command yq ""

declare -A SHADOWSOCKS
export SHADOWSOCKS

EVNFILE=${EVNFILE:-"${ROOT_DIR}/.options"}

while getopts ":hvf:m:p:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    v)
        set -x
        export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        ;;
    f)
        EVNFILE=$(readlink -f "${OPTARG}")
        ;;
    m)
        SHADOWSOCKS[SIP003_PLUGIN_OPTS]=$OPTARG
        ;;
    p)
        SHADOWSOCKS[SIP003_PLUGIN]=$OPTARG
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

if [[ ${1} != clean && ${1} != restart && ${1} != start && ${1} != stop ]] || [[ $# -eq 2 && ! -d "${ROOT_DIR}/${2}" ]]; then
    print_usage
    exit 1
fi
if [[ $# -eq 1 && ${1} != clean ]]; then
    echo "The second parameter is required for ${1}"
    exit 1
fi

if [[ -n ${EVNFILE} ]]; then touch "${EVNFILE}"; fi
EVNFILE=$(readlink -f "${EVNFILE}")
if [[ -f "${ROOT_DIR}/pre.sh" ]]; then source "${ROOT_DIR}/pre.sh"; fi

COMPOSE_PROJECT_NAME=$(basename "${ROOT_DIR}")
export COMPOSE_PROJECT_NAME

if [[ $# -eq 2 ]]; then
    if [[ -f "${ROOT_DIR}/${2}/env.sh" ]]; then source "${ROOT_DIR}/${2}/env.sh"; fi
    if [[ ! -f "${ROOT_DIR}/${2}/docker-compose.yaml" ]]; then
        echo "${ROOT_DIR}/${2}/docker-compose.yaml is not generated"
        exit 1
    fi
fi

if [[ ${1} == clean ]]; then
    while IFS= read -r _container; do
        docker container rm -f -v "${_container}"
    done < <(docker ps -a --format '{{.Names}}' | grep -E "^${COMPOSE_PROJECT_NAME}")
    #shellcheck disable=SC2086
    while IFS= read -r _dir; do
        if [[ -f "${_dir}clean.sh" ]]; then
            bash "${_dir}clean.sh"
        fi
    done < <(ls -1d ${ROOT_DIR}/*/)
    _delete_firewall_port "${SHADOWSOCKS[KCPTUN_PORT]}" "${SHADOWSOCKS[SHADOWSOCKS_PORT]}"
elif [[ ${1} == restart ]]; then
    docker compose -f "${ROOT_DIR}/${2}/docker-compose.yaml" restart
    if [[ ${2} == server ]]; then
        _add_firewall_port "${SHADOWSOCKS[KCPTUN_PORT]}" "${SHADOWSOCKS[SHADOWSOCKS_PORT]}"
    fi
elif [[ ${1} == start ]]; then
    docker compose -f "${ROOT_DIR}/${2}/docker-compose.yaml" up -d
    if [[ ${2} == server ]]; then
        _add_firewall_port "${SHADOWSOCKS[KCPTUN_PORT]}" "${SHADOWSOCKS[SHADOWSOCKS_PORT]}"
    fi
elif [[ ${1} == stop ]]; then
    docker compose -f "${ROOT_DIR}/${2}/docker-compose.yaml" stop
else
    echo "Unknown opereation"
fi

if [[ -f "${ROOT_DIR}/post.sh" ]]; then source "${ROOT_DIR}/post.sh"; fi
