#!/bin/bash

JMETER_VERSION="5.6.3"
CONTAINER_NAME="jmeter"
CONTAINER_IMAGE="liukunup/jmeter:${JMETER_VERSION}"

# example: ./run_jmeter.sh jmeter -v
docker run --rm --name=${CONTAINER_NAME} -i -v "${PWD}:/opt/workspace" -w "/opt/workspace" \
  -e JVM_ARGS="-Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m" \
  ${CONTAINER_IMAGE} $@
