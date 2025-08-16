#!/bin/bash
# shellcheck disable=SC2155

set -e

# set -x
# export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
THIS_DIR=$(dirname "${THIS_DIR}")

export KCP_SEED=${KCP_SEED:-"$(tr -cd '[:alnum:]' </dev/urandom | fold -w10 | head -n1)"}
export PREFIX=$(hostname)
export SHADOWSOCKS_METHOD=aes-128-gcm
export SHADOWSOCKS_PASSWORD=${SHADOWSOCKS_PASSWORD:-"$(tr -cd '[:alnum:]' </dev/urandom | fold -w10 | head -n1)"}
export VLESS_ID=$(cat /proc/sys/kernel/random/uuid)

_commands=(docker jq sponge yq)
for _cmd in "${_commands[@]}"; do
    if ! command -v "${_cmd}" 1>/dev/null 2>&1; then
        echo "${_commands[@]}" "are required and ${_cmd} is missing"
        exit 1
    fi
done

"${THIS_DIR}"/create.sh
"${THIS_DIR}"/create.sh -s kcp
"${THIS_DIR}"/create.sh -p shadowsocks
"${THIS_DIR}"/create.sh -p shadowsocks -s kcp

RUNTIME="${THIS_DIR}"/all-in-one-server
mkdir -p "${RUNTIME}" || true
cp "${THIS_DIR}"/run.sh "${THIS_DIR}"/.*.options "${THIS_DIR}"/vless-xhttp-server/docker-compose.yaml "${THIS_DIR}"/vless-xhttp-server/config.json "${THIS_DIR}"/vless-xhttp-server/xray* "${RUNTIME}"/

jq '.inbounds = []' "${RUNTIME}/config.json" | sponge "${RUNTIME}/config.json"
yq -i '.services.server.ports=[]' "${RUNTIME}/docker-compose.yaml"
yq -i '.services.server.container_name="xray-server"' "${RUNTIME}/docker-compose.yaml"

declare -a PORTS=()
for _item in shadowsocks-kcp-server shadowsocks-xhttp-server vless-kcp-server vless-xhttp-server; do
    jq '.inbounds += input.inbounds' "${RUNTIME}"/config.json "${THIS_DIR}/${_item}"/config.json | sponge "${RUNTIME}"/config.json
    _port=$(jq '.inbounds[0].port' "${THIS_DIR}/${_item}"/config.json)
    PORTS+=("${_port}")
done

mapfile -t PORTS < <(printf "%s\n" "${PORTS[@]}" | sort -n)
for _port in "${PORTS[@]}"; do
    yq -i '.services.server.ports += "'"${_port}":"${_port}"'/tcp"' "${RUNTIME}/docker-compose.yaml"
    yq -i '.services.server.ports += "'"${_port}":"${_port}"'/udp"' "${RUNTIME}/docker-compose.yaml"
done
