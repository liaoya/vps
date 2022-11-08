#!/bin/bash
# 0 * * * * /root/ping-host.sh -c 3600 107.172.219.4

function print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS] HOST
    -h, Show the help
    -c CNT, Send only CNT pings. ${CNT:+the default is ${CNT}}
    -o DEST, Store the result. ${DEST:+the default is ${DEST}}
EOF
}

CNT=${CNT:-3600}
DEST=${DEST:-/root}

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

_tmp_file=$(mktemp)
declare -r _tmp_file
#shellcheck disable=SC2064
trap \
    "{ rm -fr ${_tmp_file}; }" \
    SIGINT SIGTERM ERR EXIT

FILENAME=${_tmp_file}/$(date "+%Y%m%d-%H%M%S").txt
ping -c "${CNT}" "${1}" 1>"${FILENAME}" 2>&1

dt=$(basename -s .txt "${FILENAME}")
loss=$(grep "packets transmitted" "${FILENAME}" | cut -d, -f3 | cut -d% -f1 | tr -d " ")
min=$(grep "round-trip min/avg/max" "${FILENAME}" | cut -d= -f2 | cut -d" " -f2 | cut -d/ -f1)
avg=$(grep "round-trip min/avg/max" "${FILENAME}" | cut -d= -f2 | cut -d" " -f2 | cut -d/ -f2)
max=$(grep "round-trip min/avg/max" "${FILENAME}" | cut -d= -f2 | cut -d" " -f2 | cut -d/ -f3)
printf "%s,%d,%.3f,%.3f,%.3f\n" "${dt}" "${loss}" "${avg}" "${min}" "${max}" | tee -a "${DEST}/${1}.txt"
