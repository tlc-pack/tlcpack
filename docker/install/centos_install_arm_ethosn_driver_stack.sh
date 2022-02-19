#!/bin/bash

set -e

source /multibuild/manylinux_utils.sh
python3_bin="$(cpython_path 3.7)/bin/python"

repo_url="https://github.com/Arm-software/ethos-n-driver-stack"
repo_dir="ethosn-driver"
repo_revision="21.08"
install_path="/opt/arm/$repo_dir"

tmpdir=$(mktemp -d)

# install dependencies for building Arm(r) Ethos(tm)-N series Driver Stack
yum install -y sparse bc devtoolset-7-gcc-c++ wget

source /opt/rh/devtoolset-7/enable

toolchain_bin_path=$(which g++)
toolchain_path=$(dirname "$toolchain_bin_path")

install_scons()
{
  ${python3_bin} -mvenv v
  . v/bin/activate
  pip install wheel scons
}

cleanup()
{
  rm -rf "$tmpdir"
}

trap cleanup 0

cd "$tmpdir"

git clone "$repo_url" "$repo_dir"

install_scons

cd "$repo_dir"
git checkout "$repo_revision"

cd "driver"

# setting PATH is needed here, due to a bug with scons in CentOS/RHEL
# see: https://github.com/godotengine/godot/issues/34533
scons install_prefix="$install_path" install PATH="$toolchain_path"
