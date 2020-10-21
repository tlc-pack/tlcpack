#!/usr/bin/env bash

set -e

cd ${GITHUB_WORKSPACE}
echo ${INPUT_SCRIPT}
bash ${INPUT_SCRIPT}
