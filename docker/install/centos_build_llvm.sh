#!/bin/bash

set -e

LLVM_VERSION_MAJOR=$1

source /multibuild/manylinux_utils.sh

detect_llvm_version() {
  curl -sL "https://api.github.com/repos/llvm/llvm-project/releases?per_page=50" | \
    grep tag_name | \
    grep -o "llvmorg-${LLVM_VERSION_MAJOR}[^\"]*" | \
    grep -v rc | \
    sed -e "s/^llvmorg-//g" | \
    head -n 1
}

LLVM_VERSION=$(detect_llvm_version)
echo ${LLVM_VERSION}
curl -sL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz -o llvm-${LLVM_VERSION}.src.tar.xz
unxz llvm-${LLVM_VERSION}.src.tar.xz
tar xf llvm-${LLVM_VERSION}.src.tar
pushd llvm-${LLVM_VERSION}.src
mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;X86" \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_USE_INTEL_JITEVENTS=ON \
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON \
    -DPYTHON_EXECUTABLE="$(cpython_path 3.6)/bin/python" \
    -GNinja \
    ..
ninja install
popd
popd
rm -rf llvm-${LLVM_VERSION}.src.tar.xz llvm-${LLVM_VERSION}.src.tar llvm-${LLVM_VERSION}.src


# clang is only used to precompile Gandiva bitcode
if [ ${LLVM_VERSION_MAJOR} -lt 9 ]; then
  clang_package_name=cfe
else
  clang_package_name=clang
fi
curl -sL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/${clang_package_name}-${LLVM_VERSION}.src.tar.xz -o ${clang_package_name}-${LLVM_VERSION}.src.tar.xz
unxz ${clang_package_name}-${LLVM_VERSION}.src.tar.xz
tar xf ${clang_package_name}-${LLVM_VERSION}.src.tar
pushd ${clang_package_name}-${LLVM_VERSION}.src
mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON \
    -GNinja \
    ..
ninja -w dupbuild=warn install # both clang and llvm builds generate llvm-config file
popd
popd
rm -rf ${clang_package_name}-${LLVM_VERSION}.src.tar.xz ${clang_package_name}-${LLVM_VERSION}.src.tar ${clang_package_name}-${LLVM_VERSION}.src
