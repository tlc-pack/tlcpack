#!/bin/bash

set -e
set -u
set -o pipefail

# install libraries for building c++ core on ubuntu
yum install -y wget xz python-pip python3-pip python34-pip

# install multibuild utils
git clone https://github.com/matthew-brett/multibuild.git && cd multibuild && \
    git checkout 9e2349833e994cb829b77cc08f1aacc6ab6d2458

# install argparse
pip3 install argparse
