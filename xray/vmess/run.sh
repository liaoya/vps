#!/bin/bash
#shellcheck disable=SC1090,SC1091

set -ae

ROOT_DIR=$(readlink -f "${BASH_SOURCE[0]}")
ROOT_DIR=$(dirname "${ROOT_DIR}")
export ROOT_DIR

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] <clean|restart|start|stop> <client|server>
EOF
}

function _add_ufw_port() {
    while (($#)); do
        if ! sudo ufw status numbered | sed '1,4d' | sed -s 's/\[ /\[/g' | tr -d '[]' | cut -d' ' -f2 | grep -s -q -w "${1}"; then
            sudo ufw allow "${1}"
        fi
        shift
    done
}

function _delete_ufw_port() {
    while (($#)); do
        while IFS= read -r num; do
            echo "y" | sudo ufw delete "${num}"
        done < <(sudo ufw status numbered | sed '1,4d' | sed -s 's/\[ /\[/g' | tr -d '[]' | cut -d' ' -f1,2 | grep -w "${1}" | tac | cut -d' ' -f1)
        shift
    done
}

declare -A XRAY
export XRAY

if [[ -f "${ROOT_DIR}/pre.sh" ]]; then source "${ROOT_DIR}/pre.sh"; fi

while getopts ":hv" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    v)
        set -x
        export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
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
if [[ $# -eq 1 && ! ${1} != clean ]] ; then
    echo "The second parameter is required for ${1}"
    exit 1
fi

PROJECT=$(basename "${ROOT_DIR}")
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
    done < <(docker ps -a --format '{{.Names}}' | grep -E "^${PROJECT}")
    #shellcheck disable=SC2086
    while IFS= read -r _dir; do
        if [[ -f "${_dir}clean.sh" ]]; then
            bash "${_dir}clean.sh"
        fi
    done < <(ls -1d ${ROOT_DIR}/*/)
    _delete_ufw_port "${SHADOWSOCKS[KCPTUN_PORT]}" "${SHADOWSOCKS[SHADOWSOCKS_PORT]}"
elif [[ ${1} == restart ]]; then
    docker-compose -p "${PROJECT}" -f "${ROOT_DIR}/${2}/docker-compose.yaml" restart
    if [[ ${2} == server ]]; then
        _add_ufw_port "${XRAY[PORT]}" "${XRAY[MKCP_PORT]}"
    fi
elif [[ ${1} == start ]]; then
    docker-compose -p "${PROJECT}" -f "${ROOT_DIR}/${2}/docker-compose.yaml" up -d
    if [[ ${2} == server ]]; then
        _add_ufw_port "${XRAY[PORT]}" "${XRAY[MKCP_PORT]}"
    fi
elif [[ ${1} == stop ]]; then
    docker-compose -p "${PROJECT}" -f "${ROOT_DIR}/${2}/docker-compose.yaml" stop
else
    echo "Unknown opereation"
fi
if [[ -f "${ROOT_DIR}/post.sh" ]]; then source "${ROOT_DIR}/post.sh"; fi
