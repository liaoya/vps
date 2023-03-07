#!/bin/bash

set -e

function add_simple_section() {
    local config type section params
    config=$1
    shift
    type=$1
    shift
    eval "declare -A params=${1#*=}"
    section=$(uci add "$config" "$type")
    for key in "${!params[@]}"; do
        uci set "$config"."$section"."$key"="${params[$key]}"
        # uci set "$config".@"$type"[-1]."$key"="${params[$key]}"
    done
    uci commit "$config"
    # sleep 1s
}

function check_param() {
    while (($#)); do
        if [[ -z ${!1} ]]; then
            echo "\${$1} is required"
            return 1
        fi
        shift
    done
}

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") OPTIONS
    -h, show the help
    -v, verbose mode
    -f FILENAME, The configure file. ${FILENAME:+the default is ${FILENAME}}
    -n NAME, the name in ssr-plus. ${NAME:+the default is ${NAME}}
    -s SERVER, The server. ${SERVER:+the default is ${SERVER}}
    -u USER, the user. ${SERVER:+the default is ${SERVER}}
EOF
}

while getopts ":hvf:n:s:u:" opt; do
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
        FILENAME=$(readlink -f "${OPTARG}")
        ;;
    n)
        NAME=${OPTARG}
        ;;
    s)
        SERVER=${OPTARG}
        ;;
    u)
        USER=${OPTARG}
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

check_param FILENAME NAME SERVER USER
