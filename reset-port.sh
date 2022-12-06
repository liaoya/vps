#!/bin/bash

set -e

ROOT_DIR=$(readlink -f "${BASH_SOURCE[0]}")
ROOT_DIR=$(dirname "${ROOT_DIR}")

function reset_ss() {
    if [[ -f "${ROOT_DIR}/ss-rust/.options" ]]; then
        "${ROOT_DIR}"/ss-rust/run.sh clean
        sed -i "/port/d" "${ROOT_DIR}"/ss-rust/.options
        "${ROOT_DIR}"/ss-rust/run.sh start server
    fi
}

function reset_vmess() {
    if [[ -f "${ROOT_DIR}/v2ray/vmess/.options" ]]; then
        "${ROOT_DIR}"/v2ray/vmess/run.sh clean
        sed -i "/port/d" "${ROOT_DIR}"/v2ray/vmess/.options
        "${ROOT_DIR}"/v2ray/vmess/run.sh start server
    fi
}

reset_ss
reset_vmess
