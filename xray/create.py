#!/usr/bin/env python3

import argparse


from typing import Any


def create_kcp_option() -> dict[str, Any]:
    mm = {}
    return mm


def create_shadowsocks_option() -> dict[str, Any]:
    mm = {}
    return mm


def write_option_file(filename: str, mm: dict[str, Any]):
    ll = sorted(mm.keys())
    with open(filename, "w") as fp:
        for key in ll:
            print(f"{key}={mm[key]}", file=fp)


def main(filename: str, mode: str, protocal: str, stream: str):
    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create Xray config file and docker-compose.yaml",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("-o", "--option-file", help="option file name")
    parser.add_argument(
        "-m", "--mode", choices=("client", "server"), default="server", help=""
    )
    parser.add_argument(
        "-p", "--protocol", choices=("shadowsocks", "vless"), default="vless", help=""
    )
    parser.add_argument(
        "-s", "--stream", choices=("kcp", "quic"), default="kcp", help=""
    )
    parser.add_argument("-v", "-verbose", action="count", default=0, help="")
    args = parser.parse_args()
    main(args.option_file, args.mode, args.protocal, args.stream)
