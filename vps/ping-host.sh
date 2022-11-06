#!/bin/bash
# 0 * * * * /root/ping-host.sh -c 3000 107.172.219.4

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS] HOST
    -h, Show the help
    -c CNT, Send only CNT pings. ${CNT:+the default is ${CNT}}
EOF
}

CNT=100

while getopts ":hc:" opt; do
    case $opt in
    h)
        print_usage
        exit 0
        ;;
    c)
        CNT=${OPTARG}
        ;;
    \?)
        print_usage
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

FILENAME=/tmp/tmp/${1}-$(date "+%Y%m%d-%H%M%S").txt
ping -c "${CNT}" "${1}" 1>"${FILENAME}" 2>&1
gzip "${FILENAME}"
