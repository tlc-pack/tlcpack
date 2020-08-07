#!/usr/bin/env bash

set -e
set -u
set -o pipefail

DOCKER_TAG="0.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../pip" && pwd)"

function usage() {
    echo "Usage: $0 [--python PYTHON_VERSION] [--cuda CUDA_VERSION] "
}

function build_wheel() {
    CUDA="$1"
    if [[ ${CUDA} == "none" ]]; then
        DOCKER_IMAGE="tlcpack/package-cpu:${DOCKER_TAG}"
        CUDA_ENV=""
        echo "Building wheel for CPU only"
    else
        DOCKER_IMAGE="tlcpack/package-cu${CUDA/./}:${DOCKER_TAG}"
        CUDA_ENV=" --gpus all "
        echo "Building wheel with CUDA ${CUDA}"
    fi
    
    echo "Running docker image ${DOCKER_IMAGE}"
    docker run --rm --pid=host \
       -v ${SCRIPT_DIR}:/workspace/scripts:ro \
       -v ${PIP_DIR}:/workspace/pip \
       ${CUDA_ENV} \
       ${DOCKER_IMAGE} \
       /workspace/scripts/build_tvm.sh --cuda ${CUDA}
}

CUDA_VERSION=("none" "10.0" "10.1" "10.2")

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --cuda)
            CUDA_VERSION=("$2")
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

mkdir -p ${PIP_DIR}
for cuda in ${CUDA_VERSION[@]}; do
    build_wheel ${cuda}
done
