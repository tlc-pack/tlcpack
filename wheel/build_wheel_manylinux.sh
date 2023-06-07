#!/usr/bin/env bash

source /multibuild/manylinux_utils.sh

function usage() {
    echo "Usage: $0 [--cuda CUDA]"
    echo
    echo -e "--cuda {none 10.2 11.1 11.3 11.6 11.7 11.8 12.1}"
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
    python_dir=$1
    PYTHON_BIN="${python_dir}/bin/python"

    cd "${TVM_PYTHON_DIR}" && \
        ${PYTHON_BIN} setup.py bdist_wheel
}

function audit_tlcpack_wheel() {
    python_version_str=$1

    cd "${TVM_PYTHON_DIR}" && \
      mkdir -p repaired_wheel && \
      auditwheel repair ${AUDITWHEEL_OPTS} dist/*cp${python_version_str}*.whl
}

TVM_PYTHON_DIR="/workspace/tvm/python"
PYTHON_VERSIONS_CPU=("3.7" "3.8" "3.9" "3.10" "3.11")
PYTHON_VERSIONS_GPU=("3.7" "3.8" "3.9" "3.10" "3.11")
CUDA_OPTIONS=("none" "10.2" "11.1" "11.3" "11.6" "11.7" "11.8" "12.1")
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
    echo 'CUDA can only be {"none", "10.2", "11.1", "11.3", "11.6" "11.7" "11.8" "12.1"}'
    exit -1
fi

if [[ ${CUDA} == "none" ]]; then
    echo "Building TVM for CPU only"
    PYTHON_VERSIONS=${PYTHON_VERSIONS_CPU[*]}
else
    echo "Building TVM with CUDA ${CUDA}"
    PYTHON_VERSIONS=${PYTHON_VERSIONS_GPU[*]}
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

    # Remove the . in version string, e.g. "3.8" turns into "38"
    python_version_str="$(echo "${python_version}" | sed -r 's/\.//g')"
    cpython_dir="/opt/conda/envs/py${python_version_str}/"

    # For compatibility in environments where Conda is not installed,
    # revert back to previous method of locating cpython_dir.
    if ! [ -d "${cpython_dir}" ]; then
      cpython_dir=$(cpython_path "${python_version}" "${UNICODE_WIDTH}" 2> /dev/null)
    fi

    if [ -d "${cpython_dir}" ]; then
      echo "Generating package for Python ${python_version}."
      build_tlcpack_wheel ${cpython_dir}

      echo "Running auditwheel on package for Python ${python_version}."
      audit_tlcpack_wheel ${python_version_str}
    else
      echo "Python ${python_version} not found. Skipping.";
    fi

done

