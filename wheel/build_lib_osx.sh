#!/bin/bash

set -e
set -u

cd tvm
rm -f config.cmake
rm -rf build
mkdir -p build
cd build

MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-10.15}

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
      -DUSE_RPC=ON \
      -DUSE_CPP_RPC=OFF \
      -DUSE_SORT=ON \
      -DUSE_RANDOM=ON \
      -DUSE_GRAPH_RUNTIME_DEBUG=ON \
      -DUSE_LLVM="llvm-config --link-static" \
      -DHIDE_PRIVATE_SYMBOLS=ON \
      -DUSE_ETHOSU=ON \
      -DUSE_CMSISNN=ON \
      -DUSE_MICRO=ON \
      -DUSE_MICRO_STANDALONE_RUNTIME=ON \
      -DUSE_METAL=ON \
      ..

make -j3
cd ../..
