#!/bin/bash
#shellcheck disable=SC2312

set -e

function add_ss() {
    local _kcp _name _password _port _server params
    _name=$1
    _server=$2
    _port=$3
    _password=$4
    shift 4
    if [[ $# -ge 1 ]]; then
        _kcp=$1
        shift 1
    else
        _kcp=0
    fi

    params=(
        [encrypt_method_ss]=aes-256-gcm
        [local_port]="1234"
        [password]="${_password}"
        [server]="${_server}"
        [type]=ss
    )
    if [[ ${_kcp} -gt 0 ]]; then
        params+=(
            [alias]="${_name}-ss-kcp"
            [kcp_enable]="1"
            [kcp_param]="--crypt none --quiet --nocomp --mode fast2 --mtu 1350 --conn 3"
            [kcp_port]="${_port}"
        )
    else
        params+=(
            [alias]="${_name}-ss"
            [fast_open]="1"
            [server_port]="${_port}"
        )
    fi

    if [[ $# -eq 2 && -n $1 ]]; then
        params+=([plugin]="$1" [plugin_opts]="$2")
    fi
    add_simple_section shadowsocksr servers "$(declare -p params)"
}

function add_simple_section() {
    local config type section params
    config=$1
    shift
    type=$1
    shift
    eval "declare -A params=${1#*=}"
    section=$(uci add "${config}" "${type}")
    for key in "${!params[@]}"; do
        uci set "${config}"."${section}"."${key}"="${params[${key}]}"
        # uci set "$config".@"$type"[-1]."$key"="${params[$key]}"
    done
    # uci commit "${config}"
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

function parse_ss() {
    local _filename _name
    local _password _plugin _plugin_opts _port _server

    _name=$1
    _filename=$2

    _password=$(grep -i "^shadowsocks_password=" "${_filename}" | cut -d'=' -f2-)
    _plugin=$(grep -i "^sip003_plugin=" "${_filename}" | cut -d'=' -f2-)
    _plugin_opts=$(grep -i "^sip003_plugin_opts=" "${_filename}" | cut -d'=' -f2-)
    _port=$(grep -i "^shadowsocks_port=" "${_filename}" | cut -d'=' -f2-)
    _server=$(grep -i "^shadowsocks_server=" "${_filename}" | cut -d'=' -f2-)

    add_ss "${_name}" "${_server}" "${_port}" "${_password}" 0 "${_plugin}" "${_plugin_opts}"
}

function parse_ss_kcp() {
    local _filename _name
    local _password _plugin _plugin_opts _port _server

    _name=$1
    _filename=$2

    _password=$(grep -i "^shadowsocks_password=" "${_filename}" | cut -d'=' -f2-)
    _plugin=$(grep -i "^sip003_plugin=" "${_filename}" | cut -d'=' -f2-)
    _plugin_opts=$(grep -i "^sip003_plugin_opts=" "${_filename}" | cut -d'=' -f2-)
    _port=$(grep -i "^kcptun_port=" "${_filename}" | cut -d'=' -f2-)
    _server=$(grep -i "^shadowsocks_server=" "${_filename}" | cut -d'=' -f2-)

    add_ss "${_name}" "${_server}" "${_port}" "${_password}" 1 "${_plugin}" "${_plugin_opts}"
}

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") OPTIONS
    -h, show the help
    -v, verbose mode
    -f FILENAME, The configure file. ${FILENAME:+the default is ${FILENAME}}
    -n NAME, the name in ssr-plus. ${NAME:+the default is ${NAME}}
    -t TYPE, One of shadowsocks, vmess. ${TYPE:+the default is ${TYPE}}
EOF
}

while getopts ":hvf:n:t:" OPT; do
    case ${OPT} in
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
    t)
        TYPE=${OPTARG}
        ;;
    *)
        print_usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

check_param FILENAME NAME TYPE

if [[ ${TYPE} == shadowsocks ]]; then
    parse_ss "${NAME}" "${FILENAME}"
    # parse_ss_kcp "${NAME}" "${FILENAME}"
fi
