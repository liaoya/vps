#!/usr/bin/env python3

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from pathlib import Path
from typing import Mapping

import logging
import os
import sys


def read_option(filename: str)->Mapping[str, str]:
    mm = {}
    with open(filename) as fp:
        for line in fp:
            if line[0] == "#":
                continue
            idx = line.find("=")
            if idx < 0:
                logging.warning("%s is illegal", )
            key = line[:idx]
            if key in mm:
                logging.warning("%s exists", key)
                sys.exit(1)
            mm[key] = line[idx+1:].strip()
    return mm


def create_ssr_plus(mm):
    pass


def create_passwall(mm):
    pass


def main(filename: str):
    mm = read_option(filename)
    create_ssr_plus(mm)
    create_passwall(mm)


if __name__ == "__main__":
    parser = ArgumentParser(description="Convert pcap file to json files", formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument("-i", "--input", required=True, help="The option file")
    parser.add_argument("-v", "--verbose", action='count', default=0, help="more information")
    args = parser.parse_args()

    args = parser.parse_args()
    log_format = "%(levelname)-8s [%(filename)s:%(lineno)d] %(message)s"
    if args.verbose:
        logging.basicConfig(format=log_format, level="INFO")
    else:
        logging.basicConfig(format=log_format, level=os.environ.get("LOGLEVEL", "WARNING").upper())
    path = Path(args.input)
    if not path.exists() or not path.is_file():
        logging.error("%s is illegal", args.input)
        sys.exit(1)
    main(args.input)

