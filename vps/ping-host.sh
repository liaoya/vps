#!/bin/bash
# 0 * * * * /root/ping-host.sh -c 3000 107.172.219.4

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS] HOST
    -h, Show the help
    -c CNT, Send only CNT pings. ${CNT:+the default is ${CNT}}
    -d DEST, Store the result. ${DEST:+the default is ${DEST}}
EOF
}

CNT=100
if grep -s -q -i 'ID="openwrt"' /etc/os-release; then
    DEST=/tmp/tmp
fi

while getopts ":hc:d:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    c)
        CNT=${OPTARG}
        ;;
    d)
        DEST=$(readlink -f "${OPTARG}")
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

if [[ -z ${DEST} ]]; then
    echo "Please assign \$DEST"
    exit 1
fi

FILENAME=${DEST}/${1}-$(date "+%Y%m%d-%H%M%S").txt
ping -c "${CNT}" "${1}" 1>"${FILENAME}" 2>&1
gzip "${FILENAME}"
