#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

rm -f "${_THIS_DIR}/docker-compose.yaml" "${_THIS_DIR}/ss-server.json"

unset -v _THIS_DIR
