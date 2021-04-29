# tlcpack

[![Conda-CPU-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Conda-CPU-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AConda-CPU-Nightly)
[![Conda-GPU-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Conda-GPU-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AConda-GPU-Nightly)
[![Wheel-CPU-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Wheel-CPU-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3AWheel-CPU-Nightly)
[![Prune-Nightly](https://github.com/tlc-pack/tlcpack/workflows/Prune-Nightly/badge.svg)](https://github.com/tlc-pack/tlcpack/actions?query=workflow%3APrune-Nightly)

Tensor learning compiler binary distribution package.

## Github Actions

We use github action to build wheel and conda packages nightly.

Checkout [.github/workflows](.github/workflows)


## Build Process

1. Build docker images

```bash
./docker/build_image.sh <CONTAINER_TYPE>

CONTAINER_NAME: Type of the docker container used to build wheels, e.g., (cpu|cu100|cu101|cu102)
```

2. Build tlcpack PIP wheels.

To build wheels for all Python versions (3.6, 3.7, 3.8) with CPU and all CUDA versions (10.0, 10.1, 10.2), run

```bash
./scripts/build_pip_wheel.sh
```

To build wheels for a specific CUDA version, for example, CUDA 10.1, run

```bash
./scripts/build_pip_wheel.sh --cuda 10.1
```

Or, to build wheels for CPU only, run
```bash
./scripts/build_pip_wheel.sh --cuda none
```

Check `./scripts/build_pip_wheel.sh --help` for other options.
