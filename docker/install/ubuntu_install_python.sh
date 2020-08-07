#!/bin/bash

set -e
set -u
set -o pipefail

# install python and pip, don't modify this, modify install_python_package.sh
apt-get update
apt-get install -y software-properties-common
apt-get install -y python3.6-dev python3.7-dev python3.8-dev python3-setuptools

# Install pip & pin pip version
cd /tmp && wget -q https://bootstrap.pypa.io/get-pip.py
python3.6 get-pip.py && pip3.6 install pip==19.3.1
python3.7 get-pip.py && pip3.7 install pip==19.3.1
python3.8 get-pip.py && pip3.8 install pip==19.3.1

# Clean up
rm /tmp/get-pip.py
