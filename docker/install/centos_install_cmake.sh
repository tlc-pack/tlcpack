#!/bin/bash

set -e
set -u
set -o pipefail

/opt/python/cp37-cp37m/bin/pip install cmake ninja
ln -s /opt/python/cp37-cp37m/bin/ninja /usr/local/bin/ninja
strip /opt/_internal/cpython-3.*/lib/python3.7/site-packages/cmake/data/bin/*
