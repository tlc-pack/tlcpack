#!/usr/bin/env bash

source /multibuild/manylinux_utils.sh

function usage() {
    echo "Usage: $0 [--cuda CUDA]"
    echo
    echo -e "--cuda {none 10.0 10.1 10.2}"
    echo -e "\tSpecify the CUDA version in the TVM (default: none)."
}

function in_array() {
    KEY=$1
    ARRAY=$2
    for e in ${ARRAY[*]}; do
        if [[ "$e" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

function build_tlcpack_wheel() {
    python_version=$1

    CPYTHON_PATH="$(cpython_path ${python_version} ${UNICODE_WIDTH})"
    PYTHON_BIN="${CPYTHON_PATH}/bin/python"
    PIP_BIN="${CPYTHON_PATH}/bin/pip"

    cd "${TVM_PYTHON_DIR}" && \
      PATH="${CPYTHON_PATH}/bin:$PATH" ${PYTHON_BIN} setup.py bdist_wheel
}

function audit_tlcpack_wheel() {
    python_version=$1

    # Remove the . in version string, e.g. "3.8" turns into "38"
    python_version_str="$(echo "${python_version}" | sed -r 's/\.//g')"

    cd "${TVM_PYTHON_DIR}" && \
      mkdir -p repared_wheel && \
      auditwheel repair ${AUDITWHEEL_OPTS} dist/tlcpack*cp${python_version_str}*.whl
}

TVM_PYTHON_DIR="/workspace/tvm/python"
PYTHON_VERSIONS=("3.6" "3.7" "3.8" "3.9")
CUDA_OPTIONS=("none" "10.0" "10.1" "10.2")
CUDA="none"

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --cuda)
            CUDA=$2
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

if ! in_array "${CUDA}" "${CUDA_OPTIONS[*]}" ; then
    echo "Invalid CUDA option: ${CUDA}"
    echo
    echo 'CUDA can only be {"none", "10.0", "10.1", "10.2"}'
    exit -1
fi

if [[ ${CUDA} == "none" ]]; then
    echo "Building TVM for CPU only"
else
    echo "Building TVM with CUDA ${CUDA}"
fi

AUDITWHEEL_OPTS="--plat ${AUDITWHEEL_PLAT} -w repaired_wheels/"
if [[ ${CUDA} != "none" ]]; then
    AUDITWHEEL_OPTS="--skip-libs libcuda ${AUDITWHEEL_OPTS}"
fi

# config the cmake
cd /workspace/tvm
echo set\(USE_LLVM \"llvm-config --ignore-libllvm --link-static\"\) >> config.cmake
echo set\(HIDE_PRIVATE_SYMBOLS ON\) >> config.cmake
echo set\(USE_RPC ON\) >> config.cmake
echo set\(USE_SORT ON\) >> config.cmake
echo set\(USE_GRAPH_RUNTIME ON\) >> config.cmake
echo set\(USE_ETHOSN /opt/arm/ethosn-driver\) >> config.cmake
echo set\(USE_ARM_COMPUTE_LIB /opt/arm/acl\) >> config.cmake
echo set\(USE_MICRO ON\) >> config.cmake
echo set\(USE_MICRO_STANDALONE_RUNTIME ON\) >> config.cmake
echo set\(USE_ETHOSU ON\) >> config.cmake
echo set\(USE_CMSISNN ON\) >> config.cmake
if [[ ${CUDA} != "none" ]]; then
    echo set\(USE_CUDA ON\) >> config.cmake
    echo set\(USE_CUBLAS ON\) >> config.cmake
    echo set\(USE_CUDNN ON\) >> config.cmake
fi

# compile the tvm
mkdir -p build
cd build
cmake ..
make -j$(nproc)

UNICODE_WIDTH=32  # Dummy value, irrelevant for Python 3

# Not all manylinux Docker images will have all Python versions,
# so check the existing python versions before generating packages
for python_version in ${PYTHON_VERSIONS[*]}
do
    echo "> Looking for Python ${python_version}."
    cpython_dir="$(cpython_path ${python_version} ${UNICODE_WIDTH} 2> /dev/null)"
    if [ -d "${cpython_dir}" ]; then
      echo "Generating package for Python ${python_version}."
      build_tlcpack_wheel ${python_version}

      echo "Running auditwheel on package for Python ${python_version}."
      audit_tlcpack_wheel ${python_version}
    else
      echo "Python ${python_version} not found. Skipping.";
    fi

done

