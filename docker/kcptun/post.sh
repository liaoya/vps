#!/bin/bash

_this_dir=$(readlink -f "${BASH_SOURCE[0]}")
_this_dir=$(dirname "${_this_dir}")

rm -f "${_this_dir}/client_linux_amd64" "${_this_dir}/server_linux_amd64"

unset -v _this_dir
