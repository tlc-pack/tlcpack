#!/usr/bin/env bash

#
# Build docker image
#
# Usage: build_image.sh <CONTAINER_TYPE>
#
# CONTAINER_NAME: Type of the docker container used to build wheels, e.g.,
#                 (cpu|cu100|cu101|cu102)
#

if [[ $# -lt 1 ]]; then
    echo "$0 <CONTAINER_TYPE>"
    echo
    echo "CONTAINER_NAME: Type of the docker container used to build wheels, e.g.,"
    echo "                (cpu|cu100|cu101|cu102)"
    exit -1
fi

DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_TAG=`cat "${DOCKER_DIR}/version.txt"`

# Get the command line arguments.
CONTAINER_TYPE=$( echo "$1" | tr '[:upper:]' '[:lower:]' )
shift 1

# Check the docker file
DOCKERFILE="${DOCKER_DIR}/Dockerfile.package-${CONTAINER_TYPE}"
if [[ ! -f ${DOCKERFILE} ]]; then
    echo "${DOCKERFILE} doesn't exist. Did you provide a wrong docker container type?"
    exit -2
fi

DOCKER_IMG_NAME="tlcpack/package-${CONTAINER_TYPE}:${DOCKER_TAG}"
echo "DOCKER IMAGE NAME: ${DOCKER_IMG_NAME}"

docker build -t ${DOCKER_IMG_NAME} \
       -f "${DOCKERFILE}" \
       "${DOCKER_DIR}"
