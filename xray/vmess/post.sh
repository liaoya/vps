#!/bin/bash

tracestate=$(shopt -po xtrace) || true
set +x

grep -e "^#" "${ROOT_DIR}/.options" | sponge "${ROOT_DIR}/.options"
for _key in "${!XRAY[@]}"; do
    if [[ -n ${XRAY[${_key}]} ]]; then
        echo "${_key,,}=${XRAY[${_key}]}" >>"${ROOT_DIR}/.options"
    fi
done
sort "${ROOT_DIR}/.options" | sponge "${ROOT_DIR}/.options"

[[ -n "${tracestate}" ]] && eval "${tracestate}"
