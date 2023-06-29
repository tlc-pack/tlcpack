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

mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;X86" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_PLUGINS=ON \
    -DLLVM_USE_INTEL_JITEVENTS=ON \
    -GNinja \
    ../llvm
ninja install
popd
popd

rm -rf llvm-project-${LLVM_VERSION}.src.tar.xz llvm-project-${LLVM_VERSION}.src.tar
