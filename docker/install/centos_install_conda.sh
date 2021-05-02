#!/bin/bash

set -e
set -u
set -o pipefail

cd /tmp && wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
/tmp/Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda
rm /tmp/Miniconda3-latest-Linux-x86_64.sh
/opt/conda/bin/conda upgrade --all
/opt/conda/bin/conda clean -ya
/opt/conda/bin/conda install conda-build conda-verify
chmod -R a+w /opt/conda/
