#!/bin/bash

set -e
set -x

compute_lib_version="v23.02.1"
compute_lib_variant="arm64-v8a-neon"
compute_lib_full_name="arm_compute-${compute_lib_version}-bin-linux-${compute_lib_variant}"
compute_lib_base_url="https://github.com/ARM-software/ComputeLibrary/releases/download/${compute_lib_version}"
compute_lib_file_name="${compute_lib_full_name}.tar.gz"
compute_lib_download_url="${compute_lib_base_url}/${compute_lib_file_name}"

target_lib="${compute_lib_variant}"

extract_dir="${compute_lib_full_name}"
install_path="/opt/arm/acl"

tmpdir=$(mktemp -d)

cleanup()
{
  rm -rf "$tmpdir"
}

trap cleanup 0

cd "$tmpdir"

curl -sL "${compute_lib_download_url}" -o "${compute_lib_file_name}"
tar xzf "${compute_lib_file_name}"

mkdir -p "${install_path}"
cp -r "${extract_dir}/include" "${install_path}/"
cp -r "${extract_dir}/arm_compute" "${install_path}/include/"
cp -r "${extract_dir}/support" "${install_path}/include/"
cp -r "${extract_dir}/utils" "${install_path}/include/"
cp -r "${extract_dir}/lib/${target_lib}" "${install_path}/lib"
