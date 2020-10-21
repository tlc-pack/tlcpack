#!/bin/bash

set -e
set -u

cd ${SRC_DIR}/python
${PYTHON} setup.py install --single-version-externally-managed --record=/tmp/record.txt
