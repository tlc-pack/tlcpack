#!/usr/bin/env bash

cd /workspace/tvm

source /opt/conda/bin/activate
conda activate py37
pip install psutil pytest-xdist
bash tests/scripts/task_python_unittest.sh