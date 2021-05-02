#!/bin/bash

set -e

source /multibuild/manylinux_utils.sh

# use a forked version with skip-libs option
git clone https://github.com/tlc-pack/auditwheel
cd auditwheel
python3 -m pip install -r requirements.txt
python3 setup.py install
