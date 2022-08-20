#!/bin/bash

JMETER_VERSION=${JMETER_VERSION:-"5.5"}
CONTAINER_NAME="jmeter"
CONTAINER_IMAGE="liukunup/jmeter:${JMETER_VERSION}"

docker run --rm --name=${CONTAINER_NAME} -i -v "${PWD}:${PWD}" -w "${PWD}" "${CONTAINER_IMAGE}" "$@"
