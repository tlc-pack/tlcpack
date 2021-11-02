#!/bin/bash

set -e
set -u

GPU_OPT=""
TOOLCHAIN_OPT=""

if [ "$target_platform" == "osx-64" ]; then
    # macOS 64 bits
    GPU_OPT="-DUSE_METAL=ON"
    TOOLCHAIN_OPT="-DCMAKE_OSX_DEPLOYMENT_TARGET=10.11"
elif [ "$target_platform" == "linux-64" ]; then
    TOOLCHAIN_OPT="-DCMAKE_TOOLCHAIN_FILE=${RECIPE_DIR}/cross-linux.cmake"
fi

# When cuda is not set, we default to False
cuda=${cuda:-False}

if [ "$cuda" == "True" ]; then
    GPU_OPT="-DUSE_CUDA=ON -DUSE_CUBLAS=ON -DUSE_CUDNN=ON"
    TOOLCHAIN_OPT=""
fi

# remove touched cmake config
rm -f config.cmake
rm -rf build
mkdir -p build
cd build

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_RPC=ON \
      -DUSE_CPP_RPC=OFF \
      -DUSE_SORT=ON \
      -DUSE_RANDOM=ON \
      -DUSE_GRAPH_RUNTIME_DEBUG=ON \
      -DUSE_LLVM="llvm-config --link-static" \
      -DHIDE_PRIVATE_SYMBOLS=ON \
      -DINSTALL_DEV=ON \
      ${GPU_OPT} ${TOOLCHAIN_OPT} \
      ${SRC_DIR}

make -j${CPU_COUNT}
cd ..
