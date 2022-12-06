#!/bin/bash
#This is tool for analyze the ping-host.sh

while IFS= read -r _file; do
    _ip=$(basename -s .txt.gz "${_file}" | cut -d- -f1)
    _dt=$(basename -s .txt.gz "${_file}" | cut -d- -f2,3)
    #shellcheck disable=SC2046
    zcat "${_file}" | tail -n 2 >/tmp/tmp/$(basename -s .gz "${_file}")
    _file=/tmp/tmp/$(basename -s .gz "${_file}")
    loss=$(grep "packets transmitted" "${_file}" | cut -d, -f3 | cut -d% -f1 | tr -d " ")
    min=$(grep "round-trip min/avg/max" "${_file}" | cut -d= -f2 | cut -d" " -f2 | cut -d/ -f1)
    avg=$(grep "round-trip min/avg/max" "${_file}" | cut -d= -f2 | cut -d" " -f2 | cut -d/ -f2)
    max=$(grep "round-trip min/avg/max" "${_file}" | cut -d= -f2 | cut -d" " -f2 | cut -d/ -f3)
    printf "%s,%d,%.1f,%.1f,%.1f\n" "${_dt}" "${loss}" "${avg}" "${min}" "${max}" | tee -a "/root/${_ip}.txt"
    rm -f "${_file}"
done < <(ls -1 /tmp/tmp/*.gz)
