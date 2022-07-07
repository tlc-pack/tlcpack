#!/bin/bash

set -e

PYTHON_VERSION=$1

source /multibuild/manylinux_utils.sh

UNICODE_WIDTH=32  # Dummy value, irrelevant for Python 3
CPYTHON_PATH="$(cpython_path ${PYTHON_VERSION} ${UNICODE_WIDTH})"
PIP="${CPYTHON_PATH}/bin/pip"

PYTHON_PACKAGES="six numpy pytest cython decorator scipy tornado typed_ast mypy \
orderedset antlr4-python3-runtime attrs requests Pillow packaging junitparser synr cloudpickle xgboost==1.5.0"

${PIP} install ${PYTHON_PACKAGES}

# Also install dependencies with the conda environment.
pip install ${PYTHON_PACKAGES}
