#!/bin/bash

set -e

cd /tmp/ && git clone https://github.com/NixOS/patchelf.git
cd /tmp/patchelf && ./bootstrap.sh && ./configure && make -j4 && make check && make install
rm -r /tmp/patchelf
