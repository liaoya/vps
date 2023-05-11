#!/bin/bash

tracestate=$(shopt -po xtrace) || true
set +x

for _key in "${!XRAY[@]}"; do
    if [[ -n ${XRAY[${_key}]} ]]; then
        sed -i -e "/^${_key,,}=/d" -e "/^${_key^^}=/d" "${EVNFILE}"
    fi
done

for _key in "${!XRAY[@]}"; do
    if [[ -n ${XRAY[${_key}]} ]]; then
        echo "${_key,,}=${XRAY[${_key}]}" >>"${EVNFILE}"
    fi
done
sort "${EVNFILE}" | sponge "${EVNFILE}"

[[ -n "${tracestate}" ]] && eval "${tracestate}"
