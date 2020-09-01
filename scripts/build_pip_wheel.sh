#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docker" && pwd)"
PIP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../pip" && pwd)"
DOCKER_TAG=`cat "${DOCKER_DIR}/version.txt"`

function usage() {
    echo "Usage: $0 [--cuda CUDA] "
    echo
    echo -e "--cuda {none 10.0 10.1 10.2}"
    echo -e "\tSpecify the CUDA version in building the wheels. If not specified, build all version."
}

function in_array() {
    KEY=$1
    ARRAY=$2
    #echo $2
    for e in ${ARRAY[*]}; do
        if [[ "$e" == "$1" ]]; then
            #echo "found"
            return 0
        fi
    done
    #echo "not found"
    return 1
}

function build_wheel() {
    CUDA="$1"
    if [[ ${CUDA} == "none" ]]; then
        DOCKER_IMAGE="tlcpack/package-cpu:${DOCKER_TAG}"
        CUDA_ENV=""
        ARGS=""
        echo "Building wheel for CPU only"
    else
        DOCKER_IMAGE="tlcpack/package-cu${CUDA/./}:${DOCKER_TAG}"
        CUDA_ENV=" --gpus all "
        ARGS="--cuda ${CUDA}"
        echo "Building wheel with CUDA ${CUDA}"
    fi
    
    echo "Running docker image ${DOCKER_IMAGE}"
    ${DOCKER_DIR}/bash.sh ${DOCKER_IMAGE} scripts/build_tvm.sh ${ARGS}
}

ALL_CUDA_OPTIONS=("none" "10.0" "10.1" "10.2")
CUDA=""

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --cuda)
            CUDA=("$2")
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
if [[ ${CUDA} ]]; then
    if ! in_array "${CUDA}" "${ALL_CUDA_OPTIONS[*]}" ; then
        echo "Invalid CUDA option: ${CUDA}"
        echo
        echo 'CUDA can only be {"none", "10.0", "10.1", "10.2"}'
        exit -1
    fi
    build_wheel ${CUDA}
else
    for cuda in ${ALL_CUDA_OPTIONS[@]}; do
        build_wheel ${cuda}
    done
fi
