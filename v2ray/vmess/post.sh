#!/bin/bash

tracestate=$(shopt -po xtrace) || true
set +x

grep -e "^#" "${ROOT_DIR}/.options" | sponge "${ROOT_DIR}/.options"
for _key in "${!V2RAY[@]}"; do
    if [[ -n ${V2RAY[${_key}]} ]]; then
        echo "${_key,,}=${V2RAY[${_key}]}" >>"${ROOT_DIR}/.options"
    fi
done
sort "${ROOT_DIR}/.options" | sponge "${ROOT_DIR}/.options"

[[ -n "${tracestate}" ]] && eval "${tracestate}"
