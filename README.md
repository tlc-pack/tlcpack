# tlcpack

Tensor learning compiler binary distribution package.

## Build Process

1. Build docker images

```bash
./script/build_docker <CONTAINER_TYPE>

CONTAINER_NAME: Type of the docker container used to build wheels, e.g., (cpu|cu100|cu101|cu102)
```

2. Build tlcpack PIP wheels.

To build wheels for all Python versions (3.6, 3.7, 3.8) with CPU and all CUDA versions (10.0, 10.1, 10.2), run

```bash
./script/build_pip_wheel.sh
```

To build wheels for a specific CUDA version, for example, CUDA 10.1, run

```bash
./script/build_pip_wheel.sh --cuda 10.1
```

Or, to build wheels for CPU only, run
```bash
./script/build_pip_wheel.sh --cuda none
```
