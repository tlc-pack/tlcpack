#!/bin/bash

set -e
set -u
set -o pipefail

# i386 not available
echo deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main\
     >> /etc/apt/sources.list.d/llvm.list
echo deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic main\
     >> /etc/apt/sources.list.d/llvm.list
# 9
echo deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-9 main\
     >> /etc/apt/sources.list.d/llvm.list
echo deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-9 main\
     >> /etc/apt/sources.list.d/llvm.list
# 10
echo deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-10 main\
     >> /etc/apt/sources.list.d/llvm.list
echo deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-10 main\
     >> /etc/apt/sources.list.d/llvm.list

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
apt-get update && apt-get install -y llvm-10 clang-10
