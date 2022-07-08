#!/bin/bash

set -e
set -u
set -o pipefail

PYTHON_PACKAGES="six numpy pytest cython decorator scipy tornado typed_ast mypy \
orderedset antlr4-python3-runtime attrs requests Pillow packaging junitparser synr cloudpickle xgboost==1.5.0"

# install libraries for python package on ubuntu
pip3.6 install ${PYTHON_PACKAGES}
pip3.7 install ${PYTHON_PACKAGES}
pip3.8 install ${PYTHON_PACKAGES}
