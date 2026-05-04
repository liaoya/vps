#!/bin/bash

while IFS= read -r _dir; do
    if [[ -x "${_dir}"/run.sh ]]; then
        "${_dir}"/run.sh clean
    fi
done < <(find . -type d -iname "*-server")