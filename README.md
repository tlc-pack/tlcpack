# tlcpack

[![Conda-CPU-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Conda-CPU-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AConda-CPU-Nightly)
[![Conda-GPU-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Conda-GPU-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AConda-GPU-Nightly)
[![Wheel-WinMac-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Wheel-WinMac-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AWheel-WinMac-Nightly)
[![Wheel-ManyLinux-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Wheel-Manylinux-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AWheel-Manylinux-Nightly)
[![Prune-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Prune-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3APrune-Nightly)

Tensor learning compiler binary distribution package.

## Github Actions

We use github action to build wheel and conda packages nightly.

Checkout [.github/workflows](.github/workflows)


## Build Process

1. Build docker images

```bash
./docker/build_image.sh <CONTAINER_TYPE>

CONTAINER_NAME: Type of the docker container used to build wheels, e.g., (cpu|cpu_aarch64|cu100|cu101|cu102)
```

2. Checkout tvm and sync version

```bash
git clone https://github.com/apache/tvm --recursive
# synchronize the package version
python common/sync_package.py [tlcpack|tlcpack-nightly]
```

The nightly will point to the latest main, tlcpack
will point to a stable build hashtag defined in common/sync_package.py


3. Build tlcpack manylinux wheels.

```bash
./docker/bash.sh [docker-image] ./wheel/build_wheel_manylinux.sh --cuda none
```

To build wheels for a specific CUDA version, for example, CUDA 11.1, run

```bash
./docker/bash.sh [docker-image] ./wheel/build_wheel_manylinux.sh --cuda 11.1
```

The docker image is built in step 1 and needs to match the cuda version.

4. Get the wheels

The wheels are now available in
```bash
./tvm/python/repaired_wheels
```
