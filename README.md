# tlcpack

Tensor learning compiler binary distribution package.

## Build Process

1. Build docker images

```bash
./script/build_docker
```

2. Build tlcpack Pip wheels.

To build wheels for all Python versions (3.6, 3.7, 3.8) with CPU and all CUDA versions (10.0, 10.1, 10.2), run

```bash
./script/build_pip_wheel.sh
```

To build a specific version of wheel, for example, building wheel for CUDA 10.1, run

```bash
./script/build_pip_wheel.sh --cuda 10.1
```

Or, to build wheel for CPU only, run
```bash
./script/build_pip_wheel.sh --cuda none
```
