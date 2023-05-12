#!/bin/bash

_THIS_DIR=$(readlink -f "${BASH_SOURCE[0]}")
_THIS_DIR=$(dirname "${_THIS_DIR}")

if [[ ! -f "${_THIS_DIR}/docker-compose.yaml" ]]; then
    envsubst "$(env | sort | sed -e 's/=.*//' -e 's/^/\$/g')" <"${_THIS_DIR}/docker-compose.tpl.yaml" >"${_THIS_DIR}/docker-compose.yaml"
fi

if [[ ! -f "${_THIS_DIR}/config.json" ]]; then
    if [[ ${PROTOCOL} == shadowsocks ]]; then
        cat <<EOF | jq -S . | tee "${_THIS_DIR}/config.json"
{
  "inbounds": [
    {
      "port": "${XRAY[PORT]}",
      "protocol": "${XRAY[PROTOCOL]}"
    }
  ],
  "log": {
    "loglevel": "warning"
  },
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
        jq -S . "${_THIS_DIR}/config.json" |
            jq ".inbounds[0].settings.method=\"${XRAY[SHADOWSOCKS_METHOD]}\"" |
            jq ".inbounds[0].settings.password=\"${XRAY[SHADOWSOCKS_PASSWORD]}\"" |
            jq ".inbounds[0].settings.network=\"${XRAY[SHADOWSOCKS_NETWORK]}\"" |
            jq -S . |
            sponge "${_THIS_DIR}/config.json"
    fi
fi

unset -v _THIS_DIR
