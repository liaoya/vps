#!/bin/bash

_this_dir=$(readlink -f "${BASH_SOURCE[0]}")
_this_dir=$(dirname "${_this_dir}")

export ALPINE_BASE=${ALPINE_IMAGE:-docker.io/library/alpine:3.18.5@sha256:d695c3de6fcd8cfe3a6222b0358425d40adfd129a8a47c3416faff1a8aece389}

check_command jq

if [[ ! -f "${_this_dir}/client_linux_amd64" || ! -f "${_this_dir}/server_linux_amd64" ]]; then
    KCPTUN_VERSION=${KCPTUN_VERSION:-$(curl -sL https://api.github.com/repos/xtaci/kcptun/releases/latest | jq -r .tag_name)}
    check_param KCPTUN_VERSION
    download_url "https://github.com/xtaci/kcptun/releases/download/${KCPTUN_VERSION}/kcptun-linux-amd64-${KCPTUN_VERSION:1}.tar.gz" kcptun
    tar -C "${_this_dir}" -zxf "${DOCKER_BUILD_CACHE_DIR}/kcptun/kcptun-linux-amd64-${KCPTUN_VERSION:1}.tar.gz"
    check_file "${_this_dir}/client_linux_amd64" "${_this_dir}/server_linux_amd64"
else
    KCPTUN_VERSION=$("${_this_dir}/client_linux_amd64" -v | cut -d" " -f3)
    KCPTUN_VERSION="v${KCPTUN_VERSION}"
fi
export KCPTUN_VERSION

_image_prefix=${DOCKER_HUB_PREFIX:-docker.io/yaekee}

if [[ ${DOCKERFILE} == "${_this_dir}/Dockerfile.client" ]]; then
    add_image "${_image_prefix}/kcptun-client:${KCPTUN_VERSION}"
elif [[ ${DOCKERFILE} == "${_this_dir}/Dockerfile.server" ]]; then
    add_image "${_image_prefix}/kcptun-server:${KCPTUN_VERSION}"
else
    echo "Unkonwn ${DOCKERFILE}"
    exit 1
fi
