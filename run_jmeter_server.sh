#!/bin/bash

JMETER_VERSION=${JMETER_VERSION:-"5.6.3"}
CONTAINER_NAME="jmeter-server"
CONTAINER_IMAGE="liukunup/jmeter:${JMETER_VERSION}"

# example: sh run_jmeter_server.sh
docker run -d \
  -p 1099:1099 \
  -p 50000:50000 \
  --restart=unless-stopped \
  --name=${CONTAINER_NAME} \
  "${CONTAINER_IMAGE}" jmeter-server
