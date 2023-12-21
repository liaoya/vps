#!/usr/bin/env python3

import argparse
import json
import subprocess
import shlex

from typing import Any, Mapping, Optional

def create_kcp_option()->Mapping[str, Any]:
    mm = {}
    return mm

def create_shadowsocks_option()->Mapping[str, Any]:
    mm = {}
    return mm

def write_option_file(filename: str, mm: Mapping[str, Any]):
    ll = sorted(mm.keys())
    with open(filename, "w") as fp:
        for key in ll:
            print(f"{key}={mm[key]}", file=fp)

def main(filename: str, mode: str, operation: str, protocal: str, stream: Optional[str]):
    pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Create Xray config file and start docker-compose',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-f", "--filename", help="option file name")
    parser.add_argument("-m", "--mode", choices=("client", "server"), required=True, help="")
    parser.add_argument("-p", "--protocol", choices=("shadowsocks", "vmess", "vless"), required=True, help="")
    parser.add_argument("-s", "--stream", choices=("kcp", "quic"), help="")
    parser.add_argument("-v", "-verbose", action='count', default=0, help="")
    args = parser.parse_args()
    main()
