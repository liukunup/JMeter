#!/bin/bash

JMETER_VERSION=${JMETER_VERSION:-"5.5"}
TIMEZONE=${IMAGE_TIMEZONE:-"Asia/Shanghai"}

docker build \
  --build-arg JMETER_VERSION="${JMETER_VERSION}" \
  --build-arg TIMEZONE="${TIMEZONE}" \
  -f docker/Dockerfile \
  -t "liukunup/jmeter:${JMETER_VERSION}" .
