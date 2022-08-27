#!/bin/bash

JMETER_VERSION=${JMETER_VERSION:-"5.5"}

docker build \
  --build-arg JMETER_VERSION="${JMETER_VERSION}" \
  -f business/Dockerfile \
  -t "liukunup/jmeter:business-${JMETER_VERSION}" .
