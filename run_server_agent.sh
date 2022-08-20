#!/bin/bash

JMETER_VERSION=${JMETER_VERSION:-"5.5"}
CONTAINER_NAME="jmeter"
CONTAINER_IMAGE="liukunup/jmeter:${JMETER_VERSION}"

# example: sh run_server_agent.sh
docker run -d \
  -p 8888:4444 \
  -e SA_INTERVAL=10 \
  --restart=unless-stopped \
  --name=${CONTAINER_NAME} \
  "${CONTAINER_IMAGE}" server-agent
