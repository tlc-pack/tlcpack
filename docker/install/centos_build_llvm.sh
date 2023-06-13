#!/bin/bash

set -e

LLVM_VERSION_MAJOR=$1

source /multibuild/manylinux_utils.sh

detect_llvm_version() {
  curl -sL "https://api.github.com/repos/llvm/llvm-project/releases?per_page=100" | \
    grep tag_name | \
    grep -o "llvmorg-${LLVM_VERSION_MAJOR}[^\"]*" | \
    grep -v rc | \
    sed -e "s/^llvmorg-//g" | \
    head -n 1
}

LLVM_VERSION=$(detect_llvm_version)
echo ${LLVM_VERSION}
# LLVM
curl -sL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz -o llvm-project-${LLVM_VERSION}.src.tar.xz
unxz llvm-project-${LLVM_VERSION}.src.tar.xz
tar xf llvm-project-${LLVM_VERSION}.src.tar
pushd llvm-project-${LLVM_VERSION}.src

pushd llvm
mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;X86" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_USE_INTEL_JITEVENTS=ON \
    -DPYTHON_EXECUTABLE="$(cpython_path 3.8)/bin/python" \
    -GNinja \
    ..
ninja install
popd
popd

# clang is only used to precompile Gandiva bitcode
if [ "${LLVM_VERSION_MAJOR}" -lt 9 ]; then
  clang_package_name=cfe
else
  clang_package_name=clang
fi

pushd ${clang_package_name}
mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_MODULE_PATH="/llvm-project-${LLVM_VERSION}.src/cmake/Modules" \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -Wno-dev \
    -GNinja \
    ..
ninja -w dupbuild=warn install # both clang and llvm builds generate llvm-config file
popd
popd

popd

rm -rf llvm-project-${LLVM_VERSION}.src.tar.xz llvm-project-${LLVM_VERSION}.src.tar
