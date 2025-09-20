#!/bin/bash
# shellcheck disable=SC2155

set -e

set -x
export PS4='+(${BASH_SOURCE[0]}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
THIS_DIR=$(dirname "${THIS_DIR}")

_commands=(docker jq sponge yq)
for _cmd in "${_commands[@]}"; do
    if ! command -v "${_cmd}" 1>/dev/null 2>&1; then
        echo "${_commands[@]}" "are required and ${_cmd} is missing"
        exit 1
    fi
done

"${THIS_DIR}"/create.sh -m server -p vless -s xhttp || true
"${THIS_DIR}"/create.sh -m server -p vless -s kcp || true
"${THIS_DIR}"/create.sh -m server -p vless -p shadowsocks -s xhttp || true
"${THIS_DIR}"/create.sh -m server -p shadowsocks -s kcp || true

RUNTIME="${THIS_DIR}"/all-in-one-server
mkdir -p "${RUNTIME}" || true
cp "${THIS_DIR}"/run.sh "${THIS_DIR}"/.*.options "${THIS_DIR}"/vless-xhttp-server/docker-compose.yaml "${THIS_DIR}"/vless-xhttp-server/config.json "${THIS_DIR}"/vless-xhttp-server/xray* "${RUNTIME}"/

jq '.inbounds = []' "${RUNTIME}/config.json" | sponge "${RUNTIME}/config.json"
yq -i '.services.server.ports=[]' "${RUNTIME}/docker-compose.yaml"
yq -i '.services.server.container_name="xray-server"' "${RUNTIME}/docker-compose.yaml"

for _item in shadowsocks-kcp-server shadowsocks-xhttp-server vless-kcp-server vless-xhttp-server; do
    jq '.inbounds += input.inbounds' "${RUNTIME}"/config.json "${THIS_DIR}/${_item}"/config.json | sponge "${RUNTIME}"/config.json
    _port=$(jq '.inbounds[0].port' "${THIS_DIR}/${_item}"/config.json)
done

declare -a PORTS=()
for _item in shadowsocks-kcp-server shadowsocks-xhttp-server vless-kcp-server vless-xhttp-server; do
    # shellcheck disable=SC2207
    PORTS+=( $(yq '.services.server.ports' "${THIS_DIR}/${_item}"/docker-compose.yaml) )
done
for _port in "${PORTS[@]}"; do
    if [[ ${_port} == "-" ]]; then
        continue
    fi
    yq -i ".services.server.ports += \"${_port}\"" "${RUNTIME}/docker-compose.yaml"
done
