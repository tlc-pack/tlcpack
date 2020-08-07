#!/usr/bin/env bash

set -e
set -u
set -o pipefail

function usage() {
    echo "Usage: $0 [--cuda CUDA_VERSION]"
}

CUDA_VERSION="none"

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --cuda)
            CUDA_VERSION="$2"
            shift
            shift
            ;;
        -h|--help)
            usage
            exit -1
            ;;
        *) # unknown option
            echo "Unknown argument: $arg"
            echo
            usage
            exit -1
            ;;
    esac
done

if [[ ${CUDA_VERSION} == "none" ]]; then
    echo "Building TVM for CPU only"
else
    echo "Building TVM with CUDA ${CUDA_VERSION}"
fi

# check out the tvm
cd /workspace
git clone https://github.com/apache/incubator-tvm tvm --recursive

# config the cmake
cd /workspace/tvm
echo set\(USE_LLVM \"llvm-config-10 --ignore-libllvm\"\) >> config.cmake
echo set\(USE_RPC ON\) >> config.cmake
echo set\(USE_SORT ON\) >> config.cmake
echo set\(USE_GRAPH_RUNTIME ON\) >> config.cmake
if [[ ${CUDA_VERSION} != "none" ]]; then
    echo set\(USE_CUDA ON\) >> config.cmake
    echo set\(USE_CUBLAS ON\) >> config.cmake
    echo set\(USE_CUDNN ON\) >> config.cmake
fi

# compile the tvm
mkdir -p build
cd build
cmake ..
make -j$(nproc)

# patch the package name
cd /workspace/tvm
python3 /workspace/scripts/patch_name.py --cuda ${CUDA_VERSION}

# build the python wheel
cd /workspace/tvm/python
python3.6 setup.py bdist_wheel
python3.7 setup.py bdist_wheel
python3.8 setup.py bdist_wheel
cp /workspace/tvm/python/dist/tlcpack*whl /workspace/pip
