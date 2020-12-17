#!/usr/bin/env bash

set -e

source /multibuild/manylinux_utils.sh

CUDA_VERSION=$1
if [[ ${CUDA_VERSION} == "none" ]]; then
    PACKAGE_NAME="tlcpack"
else
    PACKAGE_NAME="tlcpack-cu${CUDA_VERSION/./}"
fi

sed -i "s/name=[\"']tvm[\"']/name=\"${PACKAGE_NAME}\"/g" python/setup.py
sed -i "s/TVM: An End to End Tensor IR\/DSL Stack for Deep Learning Systems/TLCPack: Tensor learning compiler binary distribution/g" python/setup.py
